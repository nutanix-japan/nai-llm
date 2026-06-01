# Local updates to view with MIKE

Make a change to `docs/index.md`, and publish the first version:

Deploy locally

```bash
mike deploy 2.5.0 latest
```

```
mike deploy --push --update-aliases 0.1 latest
```

Set the default version to `latest`

```
mike set-default --push latest
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
   # push main for cumulative updates
   git push origin main
   # THEN ADD THE TAG: for version releases
   git tag 0.1
   git push origin 0.1
   git push origin -f 0.1 # if the tag already exists on git_pages branch
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

# Compare 

To illustrate your new workflow, here are the exact commands you will run on your local machine for each scenario.
## 1. Minor Change (Update the current "stable" docs)
Use this when you fix a typo or update a guide within the current version.

| Step | Command | Result |
|---|---|---|
| 1. Edit | (Modify your .md files) | Changes exist only on your disk. |
| 2. Save | git add . git commit -m "docs: update install guide" | Changes are saved in your local main history. |
| 3. Push | git push origin main | CI triggers: It finds your latest tag (e.g., 2.5.0) and overwrites the content of both the /2.5.0/ and /latest/ folders on your site. |

------------------------------
## 2. Major Change (Release a brand new version)
Use this when you are ready to "lock" the old version and start a new one (e.g., moving from 2.5.0 to 2.6.0).

| Step | Command | Result |
|---|---|---|
| 1. Sync | git checkout main git pull origin main | Ensures you are tagging the absolute latest code. |
| 2. Tag | git tag 2.6.0 | Creates a "marker" in your git history for the new version. |
| 3. Push | git push origin 2.6.0 | CI triggers: It creates a new folder /2.6.0/ on your site and updates the /latest/ alias to point to it. |

------------------------------
## Comparison of the two workflows

| Feature | Minor Update (push main) | Major Update (push tag) |
|---|---|---|
| Site URL | ://yoursite.com (updated) | ://yoursite.com (updated) |
| Version Folder | ://yoursite.com (overwritten) | ://yoursite.com (created new) |
| Version Dropdown | Stays the same (e.g., "2.5.0") | Adds a new entry (e.g., "2.6.0") |
| Old Versions | Content is replaced | Content is preserved in its own folder |

## Crucial Note for First Run
Because you previously had the "gh-pages is unrelated" error, make sure your first push includes the fetch-depth: 0 change in your ci.yaml. If the CI fails on the first try, you may need to manually delete the remote gh-pages branch once to "reset" the history, but the updated YAML usually fixes this automatically.
Would you like me to show you how to test this locally one last time before pushing the YAML changes to your repo?


## Regular Flow

Glad to hear that got things moving! Here is your clear, repeatable playbook for making updates to your documentation using your exact GitHub Actions workflow structure.
------------------------------
## Strategy 1: Minor Day-to-Day Updates (No Tags)
Use this workflow when you are fixing typos, updating text, or adding small details to the existing stable version.
Your ci.yaml pipeline (PATH B) will automatically look up the highest current Git tag, overwrite that version folder's contents, and update the latest alias online without you needing to change version numbers.

# 1. Stage all your modified/new files

```bash
git add .
```

# 2. Commit your changes

```bash
git commit -m "docs: fix typo in air-gap configuration"
```

# 3. Push to main (this triggers the automated minor update workflow)

```bash
git push origin main
```

------------------------------
## Strategy 2: Major Release Updates (New Version / New Tag)
Use this workflow when you are bumping the version number (e.g., going from 2.7.0 to 2.8.0).
Your ci.yaml pipeline (PATH A) will create a brand new folder for this version name, generate an isolated copy of the docs, and dynamically point the latest alias directly to it.

# 1. Stage all your modified/new files
```bash
git add .
```
# 2. Commit your version release changes
```bash
git commit -m "release: finalize all features for 2.8.0"
```
# 3. Push your code to the main branch first
```bash
git push origin main
```
# 4. Create a brand new local tag matching your version
```bash
git tag 2.8.0
```
# 5. Push the tag to GitHub (this triggers the major release workflow)
```bash
git push origin 2.8.0
```
------------------------------
## ⚠️ Pro-Tips for Smooth Deploys

* Avoid local Mike pushes: Do not run mike deploy --push on your laptop. Let your GitHub Actions workflow handle it exclusively to prevent conflicts on your gh-pages branch.
* Testing locally: If you want to preview how things look before pushing to GitHub, rely on your local environment commands:

# Build and view a local live preview server safely without making changes
mkdocs serve --livereload

* Accidental tag mistakes: If you accidentally tag a version prematurely and need to update it with extra commits, remember you must use the force flag (-f) on both your local machine and your remote push:
```bash
git tag -f <version>
git push origin <version> -f
```

# Delete Old Versions (Tags)


To safely delete an old or incorrect version from your live website, you must manipulate the gh-pages branch where mike stores your compiled HTML files.
Because your repository uses a GitHub Actions workflow, the safest way to do this is to perform the deletion locally and push the updated branch structure back up to GitHub.
Here is the step-by-step process:
## Step 1: Delete the version from the website
Use the mike delete command locally. This removes the specified version folder and updates the underlying versions.json file that controls your drop-down menu.

# Delete a specific version folder and its reference

```bash
mike delete 2.6.0
```

# (Optional) If you also accidentally created an incorrect alias, delete it too
```bash
mike delete latest
```

## Step 2: Push the deletion directly to your deployment branch
Because this is an administrative fix (not a code change), you bypass the standard workflow and push the changes directly to your live documentation branch:

# Push the updated structure directly to GitHub Pages
```bash
mike --push
```

## Step 3: Clean up the Git Tag (If applicable)
If the version you deleted was tied to a Git tag (e.g., 2.6.0), your GitHub Action workflow might automatically re-deploy it the next time someone runs a minor update. You must delete the tag both locally and on GitHub to prevent this.

# 1. Delete the tag from your local machine
```bash
git tag -d 2.6.0
```
# 2. Delete the tag from the remote GitHub repository
```
git push origin --delete 2.6.0
```

## Step 4: Verify and reset the default page (Crucial)
If you deleted the version or alias that your website defaults to when a user visits the root URL, your site might show a 404 error. Ensure your site points to a valid remaining version or alias:

# Reset the root landing page to a valid alias or version folder
```bash
mike set-default --push latest
```

Do you need to check the exact names of the versions currently hosted on your live site before running these deletion commands?

# Always keep local and remote Sync'ed

# 1. Fetch the absolute latest changes from GitHub's gh-pages branch

```bash
git fetch origin gh-pages
```

# 2. Check the file again (it will now show 2.7.0 correctly)

```bash
git show origin/gh-pages:versions.json
```
```text
git show origin/gh-pages:versions.json                                                                                            ─╯
[
  {
    "version": "2.7.0",
    "title": "NAI 2.7.0",
    "aliases": [
      "latest"
    ]
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

# Delete old versions

Perfect, your local history is now fully synced, and 2.5.0 is clearly visible.
To completely and safely delete version 2.5.0 from your website and clean up its tracking, run these commands in your terminal:
## Step 1: Sync your local branch with the live server
Before making changes, switch your local gh-pages branch tracking to match exactly what is on GitHub:

git checkout gh-pages
git reset --hard origin/gh-pages

## Step 2: Delete the version and push the changes
Run the deletion command using mike and push the update to your live documentation site:

# Remove the 2.5.0 folder and update the dropdown configuration

```bash
mike delete 2.5.0
# Push the deletion directly to GitHub Pages
mike --push
```

## Step 3: Switch back to your working branch
Return to your primary development branch so you can resume normal documentation updates:

```bash
git checkout main
```

## Step 4: Delete the old Git Tag (Optional but Recommended)
To prevent your automated minor updates pipeline from accidentally picking up or referencing this old version number in the future, remove its Git tag:

```bash
# Delete the tag locally
git tag -d 2.5.0
# Delete the tag on GitHub
git push origin --delete 2.5.0
```

Once you complete Step 2, you can refresh your live website. Version 2.5.0 will immediately disappear from your dropdown menu.
