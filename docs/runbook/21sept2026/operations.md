# Git Workflow Troubleshooting & Environment Synchronization Guide

This runbook documents the standard operational commands for correcting accidental local commits on the `main` branch and synchronizing feature branches during structural project changes (such as our migration from Azure to GCP).

---

## Runbook 1: Extracting Accidental Commits off Local `main`

Follow these steps if you accidentally committed updates directly to your local `main` branch instead of a feature branch, and your `git push` was blocked by repository rulesets.

### Step 1: Isolate the Commits onto a New Branch
While sitting on your local `main` branch containing the unpushed commits, create a new branch. This new branch will automatically inherit your entire recent commit history.
```bash
# Create and switch to the new feature branch
git checkout -b feature/my-isolated-feature
```

### Step 2: Clear the Blocked Commits from Local `main`
Switch back to your local `main` branch and force it to match the exact, clean status of the remote server.
```bash
# Switch back to the local main branch
git checkout main

# WARNING: This resets main, discarding the unpushed commits locally
git reset --hard origin/main

# Pull down the clean, verified history to guarantee alignment
git pull origin main
```

---

## Runbook 2: Synchronizing Multi-Branch Environments During Infrastructure Migrations

When global configurations change across a codebase (e.g., migrating from Azure to GCP setups), the changes are staged by renaming the working branch to a core maintenance classification (`chore/global-config-update`), pushing it, and merging it directly into `main`. 

Once those global updates are live on the server, use the following procedures to manage your outstanding feature branches.

### Scenario A: Managing Local-Only Feature Branches
If you have open feature branches on your machine that have **never been pushed to GitHub** and contain outdated configurations, delete them entirely to avoid technical debt.

```bash
# Ensure you are standing on main before attempting deletions
git checkout main

# Force-delete the old, outdated local branch
git branch -D feature/old-outdated-branch
```
*Note: Once deleted, you can safely spawn a fresh, up-to-date branch directly from the updated `main` branch using `git checkout -b feature/new-gcp-feature`.*

### Scenario B: Managing Remote Feature Branches
If you have open feature branches that **already exist on GitHub**, you must pull the new global infrastructure configurations into them to keep them operational.

```bash
# 1. Switch to your existing remote feature branch
git checkout feature/existing-remote-branch

# 2. Fetch all changes from the server and clean old references
git fetch --prune

# 3. Merge the new global config updates from main directly into this branch
git pull origin main
```

#### Handling Post-Pull Merge Conflicts
If your remote feature branch contains files that conflict with the new GCP configuration files, your terminal will pause. Follow these steps to resolve it:
1. Open the conflicted files in your code editor (e.g., VS Code).
2. Delete the old environment configurations (e.g., Azure properties) and keep the incoming configurations (e.g., GCP infrastructure properties).
3. Save the files and finalize the sync in your terminal:
   ```bash
   # Stage the resolved files
   git add .

   # Commit the merge resolution
   git commit -m "merge: resolve infrastructure conflicts with main branch"

   # Push the synchronized feature branch back up to GitHub
   git push origin feature/existing-remote-branch
   ```
