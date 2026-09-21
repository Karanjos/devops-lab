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

## 3. Setting up the project -

### First we need to run this project from linux os, we will install wsl and then will run 

```bash
wsl -d Ubuntu -u root
``` 

then we will change the password for the default user karan_joshi.

```bash
passwd karan_joshi
```
then we will change the user to the wsl -

```bash
#both command will login the karan_joshi user
wsl -d Ubuntu -u karan_joshi/ wsl -d Ubuntu
```

after this we will install the make package.

### Docker fix --
when getting error for -

```bash
docker compose up -d postgres
[+] Running 0/1
 ⠋ postgres Pulling                                                                                                                                                         0.0s
error getting credentials - err: fork/exec /usr/bin/docker-credential-desktop.exe: exec format error, out: ``
```
we need to disable the credsStore by removing this line from the ~/.docker/config.json but first keep backup of it.

```bash
cp ~/.docker/config.json ~/.docker/config.json.bkp
nano ~/.docker/config.json
```

### If JAVA_HOME is not configure inside the WSL - we need to do this with following steps -

```bash
   sudo apt update
   sudo apt install -y openjdk-21-jdk maven
   echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
   source ~/.bashrc
```

### If we get the error during setting up the frontend as below -

```bash
karan_joshi@KaranJoshi:/mnt/c/Users/Karan Joshi/Desktop/devops-lab/frontend$npm run dev
WSL 1 is not supported. Please upgrade to WSL 2 or above.
Could not determine Node.js install directory
karan_joshi@KaranJoshi:/mnt/c/Users/Karan Joshi/Desktop/devops-lab/frontend$ cd ..
karan_joshi@KaranJoshi:/mnt/c/Users/Karan Joshi/Desktop/devops-lab$ make frontend-dev
cd frontend && npm install && npm run dev
WSL 1 is not supported. Please upgrade to WSL 2 or above.
Could not determine Node.js install directory
make: *** [Makefile:17: frontend-dev] Error 1
```

steps -

```bash
sudo apt install -y curl

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 

nvm install 22
```

### Since Java and Node both hit this, check the rest of your tools the same way: which java mvn node npm docker. Everything except docker should resolve to a Linux path (/usr/... or ~/.nvm/...). docker is expected to show the Docker Desktop integration, so a path in /usr/bin or similar is fine.

### Move the project into the Linux filesystem

```bash
cp -r "/mnt/c/Users/Karan Joshi/Desktop/devops-lab" ~/devops-lab
cd ~/devops-lab
```