# Local updates to view with MIKE

Make a change to `docs/index.md`, and publish the first version:

```
mike deploy --push --update-aliases 0.1 latest
```

Set the default version to `latest`

```
mike set-default --push latest
```

Deploy locally

```bash
mike deploy 2.5.0 latest
```

Now, make another change and publish a new version:

```
mike deploy --push --update-aliases 0.2 latest
```

# Git updates to view with MIKE

1. Daily Updates (The "Dev" version)

   Use your existing commands. This will update the dev folder on your site so you can see changes without affecting your "stable" version.
   
   ```bash
   git add .
   git commit -m "Update docs"
   git push origin main
   ```


2. Making a Official Release (The "0.1" version)
   
   When your docs are polished and you want to lock them in as a version:
  
   ```bash
   git add .
   git commit -m "Finalizing version 0.1"
   git push origin main
   # THEN ADD THE TAG:
   git tag 0.1
   git push origin 0.1
   ```


3. Why do both?
   
   ``git push origin main``: Sends your actual Markdown code to your main branch so you don't lose your work.
   ``git push origin 0.1``: This is the "signal" to your CI.yaml to run mike deploy 0.1. Without the tag push, the CI won't know to create a new version folder; it will just keep updating dev.

**Summary Rule of Thumb:**
- Just coding/writing? Just add, commit, push.
- Releasing a version? add, commit, push + tag, push tag

## Accidental commits and managing versions

If you accidentally tag a commit (e.g., you notice a typo right after pushing), you can "undo" it both locally and on GitHub with these commands.
## 1. Delete the tag locally
This removes the tag from your computer’s history.

```bash
git tag -d 0.1
```

## 2. Delete the tag from GitHub
This tells GitHub to remove the tag from the remote repository so the CI doesn't try to deploy it again.

```bash
git push --delete origin 0.1
```

## 3. Fixing and Re-tagging
Once the "bad" tag is gone, you can fix your files and re-apply the tag to the correct commit:

# 1. Fix the files


```bash
git add .
git commit -m "Fix typo in 0.1 docs"
git push origin main
# 2. Re-apply and push the tag
git tag 0.1
git push origin 0.1
```

## 4. Cleanup the Site (The "Mike" part)
Deleting the Git tag does not automatically delete the version folder from your gh-pages branch. You need to manually tell mike to remove that version from the live site:

# Delete the version from the remote gh-pages branch

```bash
mike delete --push 0.1
```

## Pro-Tip: "Moving" a tag
If you just want to move the tag to your latest commit without deleting/recreating manually:

```bash
git tag -f 0.1
git push -f origin 0.1
```

(Note: Use the -f force flag with caution, as it overwrites history!)
Do you want to see how to automate the version naming in your ci.yaml so you don't have to manually type 0.1 every time?

