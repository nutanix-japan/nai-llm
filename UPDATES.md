# MkDocs + Mike: Git Pages Update Playbook

This document covers the complete workflow for managing and deploying versioned documentation using **Mike** and **GitHub Actions**.

---

## Overview: Two Deployment Strategies

| Feature | Minor Update (push main) | Major Release (push tag) |
|---|---|---|
| When to use | Fix typos, update content in current version | Lock old version, release a new one |
| CI Path | PATH B (auto-detects latest tag) | PATH A (creates new version folder) |
| Version Folder | Existing folder overwritten | New folder created |
| Version Dropdown | Unchanged | New entry added |
| Old Versions | Content is replaced | Content preserved in its own folder |

---

## Strategy 1: Minor Day-to-Day Updates (No Tags)

Use this when fixing typos, updating text, or adding small details to the existing stable version. Your `ci.yaml` pipeline (PATH B) will automatically look up the highest current Git tag, overwrite that version folder's contents, and update the `latest` alias.

```bash
# 1. Stage all modified/new files
git add .

# 2. Commit your changes
git commit -m "docs: fix typo in air-gap configuration"

# 3. Push to main (triggers the automated minor update workflow)
git push origin main
```

---

## Strategy 2: Major Release (New Version / New Tag)

Use this when bumping the version number (e.g., from `2.7.0` to `2.8.0`). Your `ci.yaml` pipeline (PATH A) will create a brand new folder for this version and point the `latest` alias to it.

```bash
# 1. Stage all modified/new files
git add .

# 2. Commit your version release changes
git commit -m "release: finalize all features for 2.8.0"

# 3. Push code to main branch first
git push origin main

# 4. Create a new local tag matching your version
git tag 2.8.0

# 5. Push the tag to GitHub (triggers the major release workflow)
git push origin 2.8.0
```

**Summary Rule of Thumb:**
- Just coding/writing? → `add`, `commit`, `push`
- Releasing a version? → `add`, `commit`, `push` + `tag`, `push tag`

---

## Local Preview with Mike

Use these commands to preview versioned docs locally before pushing to GitHub.

```bash
# Deploy and preview version locally
mike deploy 2.5.0 latest

# Set the default version
mike set-default --push latest

# Deploy a new version locally
mike deploy --push --update-aliases 0.2 latest

# Live preview without making changes
mkdocs serve --livereload
```

> ⚠️ **Avoid running `mike deploy --push` from your laptop** once CI is set up. Let GitHub Actions handle all pushes to `gh-pages` exclusively to prevent branch conflicts.

---

## Accidental Commits: Undo a Bad Tag

If you accidentally tag a commit (e.g., you notice a typo right after pushing), follow these steps to undo it.

### Step 1: Delete the tag locally

```bash
git tag -d 0.1
```

### Step 2: Delete the tag from GitHub

```bash
git push --delete origin 0.1
```

### Step 3: Fix files and re-tag

```bash
git add .
git commit -m "Fix typo in 0.1 docs"
git push origin main

# Re-apply and push the corrected tag
git tag 0.1
git push origin 0.1
```

### Step 4: Clean up the live site (Mike)

Deleting the Git tag does **not** automatically remove the version folder from your `gh-pages` branch. You must tell Mike explicitly:

```bash
mike delete --push 0.1
```

### Pro-Tip: Move a tag to your latest commit

```bash
git tag -f 0.1
git push -f origin 0.1
```

> **Caution:** Use `-f` (force) carefully — it overwrites history.

---

## Deleting Old Versions from the Live Site

To safely remove an old version (e.g., `2.5.0`) from your live site, follow these steps.

### Step 1: Sync your local `gh-pages` branch with GitHub

```bash
git checkout gh-pages
git reset --hard origin/gh-pages
```

### Step 2: Delete the version and push

```bash
# Remove the version folder and update the dropdown
mike delete 2.5.0

# Push the deletion directly to GitHub Pages
mike --push
```

### Step 3: Switch back to your working branch

```bash
git checkout main
```

### Step 4: Delete the old Git tag (Recommended)

Prevents future CI pipelines from accidentally referencing this version.

```bash
# Delete tag locally
git tag -d 2.5.0

# Delete tag on GitHub
git push origin --delete 2.5.0
```

### Step 5: Verify and reset the default page

If you deleted the version your site defaults to, you may get a 404. Reset the landing page:

```bash
mike set-default --push latest
```

---

## Keeping Local and Remote in Sync

Always sync your local `gh-pages` state before making administrative changes.

```bash
# Fetch the latest changes from GitHub's gh-pages branch
git fetch origin gh-pages

# Verify the current versions.json
git show origin/gh-pages:versions.json
```

Example `versions.json` output:

```json
[
  {
    "version": "2.7.0",
    "title": "NAI 2.7.0",
    "aliases": ["latest"]
  },
  {
    "version": "2.6.0",
    "title": "NAI 2.6.0",
    "aliases": []
  },
  {
    "version": "2.5.0",
    "title": "NAI 2.5.0",
    "aliases": []
  }
]
```

---

## First-Run Note

If you previously encountered the `"gh-pages is unrelated history"` error, ensure your first push includes `fetch-depth: 0` in your `ci.yaml`. If the CI still fails, manually delete the remote `gh-pages` branch once to reset the history — the updated YAML will handle it automatically on the next run.

---

## ⚠️ Pro-Tips for Smooth Deploys

- **No local Mike pushes:** Let GitHub Actions exclusively manage `gh-pages` to avoid conflicts.
- **Local preview:** Use `mkdocs serve --livereload` for a safe live preview without touching the remote.
- **Accidental tags:** Use the force flag to correct a prematurely pushed tag:

```bash
git tag -f <version>
git push origin <version> -f
```
