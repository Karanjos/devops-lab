***************************** If you get propmt every time asking git credentials to provide username and password to push the code to remote repo. follow the below steps to fix it.**************************************

1) git remote -v  ::: https://github.com/Karanjos/devops-lab.git

2) ssh-keygen -t ed25519 -C "your-email@example.com"
press enter keep everything default

3) start the ssh agent

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

4) check the public key - 

cat ~/.ssh/id_ed25519.pub

Copy the complete output and add it to your Git provider:

GitHub: Settings → SSH and GPG keys

Add new ssh key and paste the above public key.

5) check the connection with the remote gtihub-

ssh -T git@github.com

6) set the remote ssh url -

git remote set-url origin git@github.com:Karanjos/devops-lab.git

7) check the remote repo url 

git remote -v 
git@github.com:Karanjos/devops-lab.git

8) Now trying to push again.

******************************************************************************************

**Find your public IP**, for the firewall rules:
   ```bash
   curl -s ifconfig.me -- 139.5.240.5
   ```

state_bucket_name = "devops-labs-510114-tfstate-7e0680"