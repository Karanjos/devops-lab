# Roadmap: how to work through this project

## How to learn from it (read this once)

For every phase, follow the same loop:

1. **Read the goal**, then try to sketch what you would build before you look at any solution.
2. **Build it by hand.** Type the commands. Do not paste blindly; copy only once you can explain each line.
3. **Break it on purpose.** Each guide has "Break it" exercises. Debugging a broken system is where the learning is.
4. **Write it down.** Keep a `NOTES.md` per phase: commands that mattered, errors you hit, and how you fixed them.
   That file becomes your interview material.
5. **Check yourself** against the "You're done when" list before moving on.

Git habit: one branch per phase (`phase-4-terraform`), merge to `main` when done, tag it (`v0.4`).

Cost habit (from Phase 4): run `terraform destroy` at the end of every session. Set an Azure budget alert
of a few dollars on day one.

## Phase map

| Phase | Theme | Built in this repo? |
|---|---|---|
| 1 | App + Maven, running locally | Yes: `docs/phase-1-app-and-maven.md` |
| 2 | Docker, Nginx, Tomcat, Kafka, Kafka Connect, compose | Yes: `docs/phase-2-containers.md` |
| 3 | Linux + shell scripting | Started (`scripts/smoke-test.sh`), tasks below |
| 4 | Terraform on Azure | Next |
| 5 | Ansible | Next |
| 6 | Jenkins CI pipeline | Next |
| 7 | Kubernetes on AKS | Next |
| 8 | CD, monitoring, rollback | Next |

---

## Phase 3: Linux and shell scripting

**Goal:** be comfortable on a Linux box and automate the boring parts.

Write these scripts in `scripts/` (bash, `set -euo pipefail`, `shellcheck`-clean):

| Script | What it does | Concepts |
|---|---|---|
| `healthcheck.sh` | Checks Nginx, API, Postgres, Kafka, Connect; exits non-zero if any fail | functions, exit codes, `curl -w`, `nc` |
| `create-topics.sh` | Creates topics idempotently with chosen partitions | args, `getopts`, idempotency |
| `backup-db.sh` / `restore-db.sh` | `pg_dump` to a timestamped, gzipped file, keep the last N | `date`, `find -mtime`, `trap`, pipes |
| `logwatch.sh` | Counts ERROR lines per minute in `docker compose logs` | `grep`, `awk`, `sort | uniq -c` |
| `deploy.sh` | Pull, build, `compose up`, wait for healthy, roll back on failure | control flow, `trap ERR` |

Also practise directly on a Linux machine or VM: `ss -ltnp`, `ps aux`, `top`/`htop`, `df -h`, `du -sh`, `journalctl -u`,
`systemctl status`, `chmod`/`chown`, `crontab -e`, a systemd unit that runs `healthcheck.sh` every minute via a timer,
`ssh` keys and `~/.ssh/config`, `sed`/`awk` one-liners.

**You're done when:** a cron or systemd timer runs your healthcheck, a backup can be restored into a fresh database,
and `shellcheck scripts/*.sh` is clean.

---

## Phase 4: Terraform on Azure

**Goal:** create Azure infrastructure from code, with remote state, that you can destroy and rebuild.

Build, in this order:
1. Install Azure CLI and Terraform. `az login`, then `az account show` to confirm the subscription.
2. A **bootstrap** step (by hand with `az`, or a tiny separate Terraform config): resource group + Storage Account +
   blob container to hold Terraform state.
3. `terraform/envs/dev/` using the `azurerm` provider and the `azurerm` backend for state.
4. Modules in `terraform/modules/`: `network` (VNet, subnets, NSG), `acr` (Azure Container Registry, Basic SKU),
   `vm` (a small Linux VM for Jenkins, SSH key auth, public IP restricted to your IP).
5. Variables, `outputs.tf` (VM IP, ACR login server), `terraform.tfvars.example`.

Commands to know cold: `init`, `fmt`, `validate`, `plan -out`, `apply`, `destroy`, `state list/show/mv/rm`,
`import`, `output`, `workspace`.

**Break it:** change a resource in the Azure portal, then run `plan` and read the drift. Delete the state file
lock and see what happens. Rename a resource and see why Terraform wants to destroy it (then fix it with `moved`).

**You're done when:** `terraform apply` builds everything from a clean checkout, and `terraform destroy` removes it all.

---

## Phase 5: Ansible

**Goal:** turn the blank VM into a working Jenkins/build server, repeatably.

Build:
- `ansible/inventory/dev.ini` (host from the Terraform output) and `ansible.cfg`.
- Roles: `common` (packages, users, ssh hardening, ufw, timezone), `docker`, `java` (21), `maven`, `jenkins` (LTS from the
  official apt repo, plugins from a list, service enabled).
- `playbooks/site.yml` that applies the roles; `ansible-vault` for the Jenkins admin password.
- Handlers, templates (Jinja2), `tags`, `--check --diff`.

**Break it:** run the playbook twice and confirm the second run reports `changed=0` (idempotency). Stop a service by hand
and re-run. Add `ansible-lint` and fix what it finds.

**You're done when:** a brand-new VM becomes a working Jenkins at `http://<ip>:8080` with one command.

---

## Phase 6: Jenkins CI pipeline

**Goal:** every push builds, tests, packages and publishes images.

`Jenkinsfile` (declarative) stages:
1. Checkout
2. Backend: `mvn -B verify` (publish JUnit results)
3. Frontend: `npm ci && npm run build`
4. Docker build for backend, frontend, connect
5. Image scan (Trivy)
6. Push to ACR, tagged with the git SHA (never only `latest`)

Learn: credentials binding (ACR service principal as Jenkins credentials), multibranch pipeline, webhooks vs polling,
agents, `post {}` blocks, shared parameters, archiving artifacts.

**Break it:** fail a unit test on purpose and watch the pipeline stop. Expire a credential. Make the Docker daemon unavailable.

**You're done when:** a commit to a branch produces tagged images in ACR and a green build page.

---

## Phase 7: Kubernetes on AKS

**Goal:** run the whole system in a cluster, declared in Git.

1. Extend Terraform with an AKS cluster (free control-plane tier, 1 to 2 small nodes) and a role assignment so AKS can pull from ACR.
2. `az aks get-credentials`, then learn `kubectl` (get, describe, logs, exec, port-forward, rollout).
3. Package the app as a **Helm chart** (or Kustomize base + overlays): Deployments for backend and frontend, Services, ConfigMaps, Secrets.
4. Kafka with the **Strimzi operator** (KRaft node pools), a `KafkaConnect` and a `KafkaConnector` resource for the JDBC sink.
5. PostgreSQL as a StatefulSet with a PVC (later: compare with Azure Database for PostgreSQL).
6. Probes: use `/api/actuator/health/liveness` and `/readiness` (already in the backend). Add resource requests/limits and an HPA.
7. Ingress: check the current status of `ingress-nginx` (the Kubernetes project announced its retirement) and pick the Gateway API,
   the AKS application routing add-on, or another maintained controller.

**Break it:** delete a pod, drain a node, set a wrong image tag, exhaust memory, break a readiness probe, and diagnose each with `kubectl`.

**You're done when:** the UI works through a public address and an order flows through the pipeline inside the cluster.

---

## Phase 8: CD, monitoring, rollback

- Add a deploy stage to Jenkins: `helm upgrade --install --atomic` with the image tag from the build.
- Install Prometheus and Grafana (kube-prometheus-stack); expose Spring Boot metrics (add the Micrometer Prometheus registry) and Kafka lag.
- Do a **rollback drill**: ship a bad version on purpose, watch probes stop the rollout, and `helm rollback`.
- Secrets done properly: Kubernetes Secrets sourced from Azure Key Vault.
- Capstone: write a runbook (`docs/runbook.md`) and a 10-minute demo of the whole flow, from `git push` to a running order.
