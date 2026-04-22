---
title: "Continuous Deployment Troubleshooting"
lastupdate: git
lastupdateauthor: "Lakshmi Balaramane"
---

## Troubleshooting

Here's a complete troubleshooting guide for the setup: 

---
### 1. Check all three components are healthy

Always start here. All three must be `Ready: True`:

```bash
flux get image repository -n flux-system
flux get image policy -n flux-system
flux get image update -n flux-system
```

If any are `False`, describe them:

```bash
kubectl describe imagerepository my-app -n flux-system
kubectl describe imagepolicy my-app -n flux-system
kubectl describe imageupdateautomation my-app -n flux-system
```

---

### 2. Check ImageRepository → ImagePolicy name linkage

The most common silent bug. The `imageRepositoryRef.name` in your `ImagePolicy` must exactly match the `metadata.name` of your `ImageRepository`:

```bash
# Get the ImageRepository name
kubectl get imagerepository -n flux-system

# Check what the ImagePolicy is referencing
kubectl get imagepolicy my-app -n flux-system -o jsonpath='{.spec.imageRepositoryRef.name}'
```

They must match. If not, delete and reapply both:

```bash
kubectl delete imagepolicy my-app -n flux-system
kubectl delete imagerepository my-app -n flux-system
# reapply with correct names
```

---

### 3. Check for stale/duplicate objects

Old objects with wrong names linger and cause confusing errors:

```bash
kubectl get imagerepository -n flux-system
kubectl get imagepolicy -n flux-system
kubectl get imageupdateautomation -n flux-system
```

Delete anything unexpected:

```bash
kubectl delete imagerepository <old-name> -n flux-system
kubectl delete imagepolicy <old-name> -n flux-system
```

---

### 4. Verify the ImagePolicy is resolving the correct tag

```bash
flux get image policy my-app -n flux-system
```

Expected output:
```
NAME    LATEST IMAGE                                    READY
my-app  docker.io/ariesbabu/app-source:3338bbe         True
```

If the tag looks wrong, check your `filterTags.pattern` and `policy.alphabetical.order`:

```yaml
filterTags:
  pattern: '^[a-f0-9]{7,}$'   # must match your actual tag format
policy:
  alphabetical:
    order: desc                 # desc = latest tag wins, asc = oldest tag wins
```

Test your regex against your actual tags:

```bash
# See what tags exist
kubectl get imagerepository my-app -n flux-system -o jsonpath='{.status.lastScanResult}'

# Test your pattern manually
echo "3338bbe" | grep -P '^[a-f0-9]{7,}$'
```

---

### 5. Check the marker in your deployment file

This is the most common cause of wrong updates:

```bash
git pull origin main
grep -rn "imagepolicy" apps/
```

Verify the marker format is exactly correct:

```yaml
# CORRECT - full image reference updated
image: docker.io/ariesbabu/app-source:3338bbe # {"$imagepolicy": "flux-system:my-app"}

# WRONG - only tag is updated, image name gets lost
image: 3338bbe # {"$imagepolicy": "flux-system:my-app:tag"}
```

Validate the marker JSON is parseable:

```bash
grep "imagepolicy" apps/base/deployment.yaml \
  | sed 's/.*# //' \
  | python3 -m json.tool
```

If it fails to parse, Flux silently skips that line with no error.

---

### 6. Check the messageTemplate syntax

If `ImageUpdateAutomation` shows `Ready: False` with a template error, the error message contains the actual struct that failed. Read it carefully:

```bash
kubectl get imageupdateautomation my-app -n flux-system \
  -o jsonpath='{.status.conditions[*].message}'
```

Common template mistakes and fixes:

```yaml
# WRONG - OldTag/NewTag don't exist on update.Change
messageTemplate: '{{range .Changed.Changes}}{{.NewTag}}{{end}}'

# WRONG - .Changed is not directly rangeable
messageTemplate: '{{range .Changed}}{{.}}{{end}}'

# CORRECT - flat iteration over all changes
messageTemplate: '{{range .Changed.Changes}}{{print .OldValue}} -> {{println .NewValue}}{{end}}'

# CORRECT - per-object detail
messageTemplate: |
  chore: update image
  {{ range $resource, $changes := .Changed.Objects -}}
  - {{ $resource.Kind }}/{{ $resource.Name }}:
  {{ range $_, $change := $changes -}}
      {{ $change.OldValue }} -> {{ $change.NewValue }}
  {{ end -}}
  {{ end -}}
```

Available fields on `Change`: `.OldValue`, `.NewValue`, `.Setter`
Available fields on `ObjectIdentifier`: `.Kind`, `.Name`, `.Namespace`, `.APIVersion`

---

### 7. Flux is fighting your manual Git edits

If Flux keeps reverting your fixes, you are losing a race condition. **Always suspend before editing:**

```bash
# 1. Suspend first - stops Flux overwriting your changes
flux suspend image update my-app

# 2. Make your fix
vim apps/base/deployment.yaml

# 3. Commit and push
git add apps/base/deployment.yaml
git commit -m "fix: correct image marker"
git push origin main

# 4. Verify the fix is actually on the remote before resuming
git show HEAD:apps/base/deployment.yaml | grep image

# 5. Only resume once confirmed
flux resume image update my-app
flux reconcile image update my-app

# 6. Watch the result
sleep 15 && git pull && git show HEAD:apps/base/deployment.yaml | grep image
```

---

### 8. Force a reconcile and watch live

When you need to trigger immediately rather than wait for the interval:

```bash
# Force all three to reconcile
flux reconcile image repository my-app
flux reconcile image policy my-app  
flux reconcile image update my-app

# Watch events live
kubectl events --for imageupdateautomation/my-app -n flux-system --watch

# Watch git log for new commits
watch -n 5 'git pull -q && git log --oneline -5'
```

---

### 9. Dump the template context when all else fails

If the messageTemplate keeps erroring and you don't know the field names, use `{{.}}` to dump the raw struct:

```yaml
messageTemplate: "{{.}}"
```

Apply it, wait for a reconcile, then read the error message — it prints the entire available data structure with real field names.

---

### Quick reference checklist

```
□ ImageRepository Ready: True
□ ImagePolicy Ready: True and resolving correct tag
□ ImageUpdateAutomation Ready: True
□ imageRepositoryRef.name matches ImageRepository metadata.name
□ No stale/duplicate objects with old names
□ Deployment marker uses {"$imagepolicy": "flux-system:my-app"} not :tag
□ Marker JSON is valid (no single quotes, has $ prefix, colon separator)
□ Marker is on the same line as the image value
□ Always suspend before editing Git files Flux manages
□ Verify git show HEAD confirms fix before resuming
```