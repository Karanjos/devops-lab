1) If I have made some commits to the main branch, then how I can change the branch with the latest commits and remove them from the main branch local setup -

-- first create a new branch, the commits will go to the newly created branch - 
```bash 
git checkout -b branch_name
```

-- then switch to main branch and run the following commands -
```bash
git checkout main

git reset --hard origin/main

git pull origin main
```

2) setting up frontend --

