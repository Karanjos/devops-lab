# ansible/

Turns the three blank VMs from `../terraform/envs/dev` into: a VM ready to run the app's
docker-compose stack, and a working Jenkins controller + SSH build agent.

## Topology

| Group              | Host(s)             | Roles applied                        |
|---------------------|----------------------|----------------------------------------|
| `app`               | app-vm                | common, docker                         |
| `jenkins_controller`| jenkins-controller-vm | common, java, jenkins_controller       |
| `jenkins_agents`    | jenkins-agent-vm       | common, java, docker, maven, jenkins_agent |

The controller reaches the agent over SSH, not JNLP: `jenkins_controller`'s tasks generate a
dedicated ed25519 keypair on the controller (`/var/lib/jenkins/.ssh/agent_key`), register it
as a Jenkins credential, and define the agent as an SSH-launched permanent node — all via a
Groovy `init.groovy.d` script this role templates in. `jenkins_agent`'s tasks then authorize
that same public key for the `jenkins` user it creates on the agent VM. Because of that
dependency, **run order matters** — see the comment at the top of `playbooks/site.yml`.

## Setup

```bash
ansible-galaxy collection install -r requirements.yml
```

1. Run `terraform apply` in `../terraform/envs/dev` first, then copy its `*_public_ip` and
   `jenkins_agent_private_ip` outputs into `inventory/dev.ini`.
2. Fill in `ansible_user` and `ansible_ssh_private_key_file` in `inventory/dev.ini` (the admin
   username and the private half of the key you put in `terraform.tfvars`).
3. Encrypt the one real secret in this repo:
   ```bash
   ansible-vault encrypt group_vars/jenkins_controller/vault.yml
   ```

## Run it

```bash
# Dry run first, always - see what would change without changing anything:
ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass

# For real:
ansible-playbook playbooks/site.yml --ask-vault-pass
```

When it finishes: `http://<jenkins_controller_public_ip>:8080`, log in with
`jenkins_admin_user` / the vaulted password, and you should see the agent node online under
**Manage Jenkins > Nodes**.

## Break it (per the roadmap's own habit)

- Run `playbooks/site.yml` twice in a row. The second run should report `changed=0` across the
  board — if it doesn't, something in that role isn't actually idempotent, go find it.
- Stop Jenkins by hand (`systemctl stop jenkins`) on the controller, re-run the playbook, confirm
  it comes back.
- Remove your IP from `allowed_ssh_cidr` in the Terraform `terraform.tfvars` and re-`apply`,
  then try to run Ansible again - diagnose the SSH timeout from first principles before looking
  at the NSG.
- Delete the agent node by hand in the Jenkins UI, re-run the playbook. The `instance.getNode(...)
  == null` check in `add-agent-node.groovy.j2` means it gets recreated on the next Jenkins
  restart this role triggers - but only on a restart, not just a re-run that changes nothing
  else. Worth tracing through why.
- Add `ansible-lint` and fix what it finds.

## You're done when

A brand-new set of three VMs becomes app VM + working Jenkins controller/agent pair with one
command (`ansible-playbook playbooks/site.yml --ask-vault-pass`), and a second run of that same
command changes nothing.
