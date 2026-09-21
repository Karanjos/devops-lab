# Repository Development & Git Workflow Guide

This document defines the mandatory branching strategy and Git development workflow for this repository. Because direct commits to the `main` branch are blocked by Repository Rulesets, all contributions must follow this lifecycle.

---

## 1. Branch Naming Strategy
Never work directly on `main`. You must always create a short-lived branch named strictly according to the scope of your changes:

| Branch Prefix | Purpose / Scope | Example |
| :--- | :--- | :--- |
| `feature/` | Application features, backend APIs, frontend UIs | `feature/backend-auth` |
| `infra/` | GCP configuration, Terraform, Kubernetes, Kafka | `infra/gke-cluster-setup` |
| `ops/` | Documentation updates, daily runbooks, hotfixes | `ops/update-runbooks` |
| `bugfix/` | Resolving an existing application bug | `bugfix/fix-login-validation` |

---

## 2. Daily Development Lifecycle (Step-by-Step)

Follow these 4 phases sequentially for every single task or change you make.

### Phase 1: Preparation (Start Clean)
Before writing any code or text, ensure your local workspace is completely synchronized with the remote repository on GitHub.

```bash
# 1. Switch back to your local main branch
git checkout main

# 2. Pull down the absolute latest changes from GitHub
git pull origin main
```

### Phase 2: Isolation (Create your Scope Branch)
Create a brand new working branch using the appropriate prefix from the naming strategy table above.

```bash
# 3. Create and immediately switch to your new branch
git checkout -b ops/update-runbooks
```
*(Replace `ops/update-runbooks` with your actual scoped branch name).*

---

### Phase 3: Implementation & Local Saving
Open your code editor, make your changes, and save them locally to your Git history.

```bash
# 4. Check which files you altered to ensure accuracy
git status

# 5. Stage your modified and newly created files
git add .

# 6. Commit your changes with a clear, descriptive message
git commit -m "ops: document git workflow guide for repository"
```

---

### Phase 4: Syncing & Pull Request Review
Because direct pushes to `main` are restricted, you must push your scoped branch up to GitHub and merge it via a Pull Request.

```bash
# 7. Push your feature/ops/infra branch to GitHub
git push origin ops/update-runbooks
```

8. **Open the Pull Request:** Open your web browser and navigate to your GitHub Repository page. Click the yellow **"Compare & pull request"** banner.
9. **Review & Merge:** Verify the file changes on your screen, add a brief description of what you completed, and click **"Create pull request"**.
10. **Finalize:** Click the green **"Merge pull request"** button, then select **"Confirm merge"**.

---

## 3. Post-Merge Cleanup (Housekeeping)
Once your code is safely integrated into the remote `main` branch on GitHub, tidy up your local computer terminal environment so it remains uncluttered.

```bash
# 11. Return to your local main branch
git checkout main

# 12. Pull down the code you just merged via the browser
git pull origin main

# 13. Delete the temporary local branch now that its job is complete
git branch -d ops/update-runbooks
```

You are now back on a clean, fully updated `main` branch and ready to repeat this cycle for your next task!
