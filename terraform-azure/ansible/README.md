# ansible/

Turns two blank VMs into: a VM ready to run the app's docker-compose stack, and a working
Jenkins controller that builds its own jobs (no separate agent VM).

## Topology

| Group     | Host(s)    | Size (Terraform)  | Roles applied                 |
|------------|-------------|---------------------|---------------------------------|
| `app`      | app-vm       | (as sized in Terraform) | common, docker              |
| `jenkins`  | jenkins-vm   | Standard_D2s_v5     | common, java, docker, maven, jenkins |

Jenkins runs as both controller and agent on `jenkins-vm`: builds run on its own built-in
node, using the executors `jenkins_executors` sets (2 by default), not on a separate SSH
agent. That's why `roles/jenkins` also puts the `jenkins` system user into the `docker`
group and overrides Jenkins' systemd unit to put Maven on `PATH` - both of those only
matter because this one box now does the building too.

## Setup

```bash
ansible-galaxy collection install -r requirements.yml
```

1. Provision `app-vm` and `jenkins-vm` (the latter sized `Standard_D2s_v5`), then copy their
   public IPs into `inventory/dev.ini`.
2. Fill in `ansible_user` and `ansible_ssh_private_key_file` in `inventory/dev.ini`.
3. Encrypt the one real secret in this repo:
   ```bash
   ansible-vault encrypt group_vars/jenkins/vault.yml
   ```

## Run it

```bash
# Dry run first, always:
ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass

# For real:
ansible-playbook playbooks/site.yml --ask-vault-pass
```

When it finishes: `http://<jenkins_vm_public_ip>:8080`, log in with `jenkins_admin_user` /
the vaulted password. Check **Manage Jenkins > Nodes > Built-In Node** shows the executor
count you set, and that a trivial pipeline (`sh 'mvn -version'`, `sh 'docker ps'`) actually
runs - that proves the PATH override and the docker group membership both landed.

## Break it

- Run `playbooks/site.yml` twice in a row. The second run should report `changed=0` across
  the board.
- `ssh` into jenkins-vm and run `sudo -u jenkins mvn -version` - works, because that's an
  interactive-ish shell with `/etc/profile.d` sourced. Then look at a pipeline job's console
  output for a step that just calls `mvn` with no path - it only works because of the
  systemd override, not because of that profile script. Temporarily comment out the
  `Environment="PATH=..."` line, re-run, and watch a build fail with `mvn: not found`
  to see the difference for yourself.
- Remove the `jenkins` user from the `docker` group by hand (`sudo gpasswd -d jenkins
  docker`), don't restart Jenkins, and run a pipeline step that calls `docker ps` - it fails
  with a permission error against the socket. Re-run the playbook and confirm it's fixed
  (remember: the group only takes effect after the next Jenkins restart, so check the
  tasks file for why `state: restarted` was used instead of `state: started` there).
- Add `ansible-lint` and fix what it finds.

## You're done when

A brand-new pair of VMs becomes app VM + working, self-building Jenkins with one command
(`ansible-playbook playbooks/site.yml --ask-vault-pass`), and a second run of that same
command changes nothing.
