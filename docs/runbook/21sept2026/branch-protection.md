# Branch Protection Setup

Activated the repository's Ruleset to block direct pushes to the `main` branch. This ensures all changes must pass through a pull request before being merged.

## Steps Followed

1. **Navigate to Rulesets**: Went to `Settings` > `Rules` > `Rulesets` in the left sidebar.
2. **Create New Ruleset**: Clicked `New ruleset` > `New branch ruleset`.
3. **Configure Settings**: Named it `Protect Main Branch` and set the status to `Active`.
4. **Target Main Branch**: Added a target condition to `Include by name` and typed `main`.
5. **Enable Restrictions**: Checked the boxes for:
   - `Require a pull request before merging`
   - `Restrict deletions`
6. **Save**: Clicked `Create` at the bottom of the page.

## How to Deploy Changes Now
Since direct commits are blocked, use this workflow in your terminal:

```bash
# 1. Start from main and pull latest changes
git checkout main
git pull origin main

# 2. Create a working feature branch
git checkout -b feature/your-feature-name

# 3. Code, stage, and commit changes
git add .
git commit -m "your descriptive commit message"

# 4. Push to GitHub and open a Pull Request (PR)
git push origin feature/your-feature-name
```
