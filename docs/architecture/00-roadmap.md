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

Cost habit (from Phase 4): you have a $300 GCP trial credit. Use a dedicated lab project, set budget alerts on day one, and run
`terraform destroy` at the end of every session, especially once the GKE cluster exists.

## Phase map

| Phase | Theme | Built in this repo? |
|---|---|---|
| 1 | App + Maven, running locally | Yes: `docs/phase-1-app-and-maven.md` |
| 2 | Docker, Nginx, Tomcat, Kafka, Kafka Connect, compose | Yes: `docs/phase-2-containers.md` |
| 3 | Linux + shell scripting | Started (`scripts/smoke-test.sh`), tasks below |
| 4 | Terraform on GCP | Next |
| 5 | Ansible | Next |
| 6 | Jenkins CI pipeline | Next |
| 7 | Kubernetes on GKE | Next |
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

## Phase 4: Terraform on GCP

**Goal:** create Google Cloud infrastructure from code, with remote state, that you can destroy and rebuild.

### Set up once (about 15 minutes)
1. Activate the free trial ($300 credit). Check the current terms for the credit's expiry (it was 90 days at the time of writing).
2. Create a **new project used only for this lab** (for example `devops-lab-<suffix>`). Deleting a project deletes everything in it,
   which is your safety net if a `terraform destroy` ever goes wrong.
3. Create budget alerts (Billing, then Budgets & alerts) at something like $25, $100 and $200. Budgets only notify you; they do not stop spending.
4. Install the `gcloud` CLI and Terraform, then:
   ```bash
   gcloud auth login
   gcloud auth application-default login   # this is the credential Terraform uses
   gcloud config set project <your-project-id>
   gcloud config set compute/region asia-south1
   ```
5. Region: `asia-south1` (Mumbai) is a safe default from Delhi because it has the widest service and machine-type availability.
   `asia-south2` (Delhi) is closer but check that everything you need is offered there before committing.

### Build, in this order
1. **Bootstrap** (by hand with `gcloud`, or a tiny separate Terraform config): enable the APIs you need
   (`compute`, `container`, `artifactregistry`, `iam`, `cloudresourcemanager`, `secretmanager`), and create a
   **GCS bucket with versioning on** to hold Terraform state. The `gcs` backend gives you state locking for free.
2. `terraform/envs/dev/` using the `google` provider and the `gcs` backend.
3. Modules in `terraform/modules/`:
   - `network`: a custom-mode VPC, a subnet (add secondary ranges for GKE pods and services now, so Phase 7 does not force a rebuild),
     firewall rules that allow SSH and the Jenkins port **only from your IP**, optionally Cloud NAT.
   - `registry`: an **Artifact Registry** Docker repository (Container Registry is the legacy product, so do not use it).
   - `vm`: a Compute Engine instance for Jenkins (`e2-medium` or `e2-standard-2`; the free `e2-micro` is too small),
     a static external IP, and a **dedicated service account** for the VM instead of the default one.
4. Variables, `outputs.tf` (VM IP, registry URL), and a `terraform.tfvars.example`.

Commands to know cold: `init`, `fmt`, `validate`, `plan -out`, `apply`, `destroy`, `state list/show/mv/rm`,
`import`, `output`, `workspace`. Plus the GCP side: `gcloud compute instances list`, `gcloud compute ssh`, `gcloud projects get-iam-policy`.

**Break it:** edit a firewall rule in the Cloud Console, then run `plan` and read the drift. Interrupt an `apply` and look at the state lock
in the bucket. Rename a resource and see why Terraform wants to destroy it (then fix it with a `moved` block).
Remove an API from the enabled list and read the error you get.

**Cost note:** a stopped VM still bills for its disk and any reserved static IP. `terraform destroy` at the end of each session is the safest habit.

**You're done when:** `terraform apply` builds everything from a clean checkout, and `terraform destroy` removes it all.

---

## Phase 5: Ansible

**Goal:** turn the blank VM into a working Jenkins/build server, repeatably.

Build:
- `ansible/inventory/dev.ini` (host from the Terraform output) and `ansible.cfg`. SSH in with OS Login or a key in instance metadata
  (`gcloud compute ssh --dry-run` prints the exact `ssh` command it would run, which is a good way to learn what it does).
- Roles: `common` (packages, users, ssh hardening, ufw, timezone), `docker`, `java` (21), `maven`, `jenkins` (LTS from the
  official apt repo, plugins from a list, service enabled).
- `playbooks/site.yml` that applies the roles; `ansible-vault` for the Jenkins admin password.
- Handlers, templates (Jinja2), `tags`, `--check --diff`.
- Stretch: replace the static inventory with the `google.cloud.gcp_compute` dynamic inventory plugin.

**Break it:** run the playbook twice and confirm the second run reports `changed=0` (idempotency). Stop a service by hand
and re-run. Add `ansible-lint` and fix what it finds. Remove your IP from the firewall rule and diagnose the SSH timeout.

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
6. Push to Artifact Registry, tagged with the git SHA (never only `latest`). Image names look like
   `asia-south1-docker.pkg.dev/<project>/<repo>/backend:<sha>`.

**Authentication, the important GCP lesson:** because Jenkins runs on a Compute Engine VM, attach a service account with
`roles/artifactregistry.writer` to it, then run `gcloud auth configure-docker asia-south1-docker.pkg.dev`. No key file is stored anywhere.
Learn the alternative too (a service-account JSON key stored as a Jenkins credential) and be able to explain why keys are the worse option:
they leak, they do not expire by default, and they need rotating.

Also learn: multibranch pipelines, webhooks vs polling, agents, `post {}` blocks, archiving artifacts.

**Break it:** fail a unit test on purpose and watch the pipeline stop. Remove the writer role and read the `403`. Make the Docker daemon unavailable.

**You're done when:** a commit to a branch produces tagged images in Artifact Registry and a green build page.

---

## Phase 7: Kubernetes on GKE

**Goal:** run the whole system in a cluster, declared in Git.

1. Extend Terraform with a **GKE Standard zonal cluster** and a small node pool (2 nodes of `e2-standard-2`, or Spot nodes to save credit).
   Use a **dedicated node service account** with `roles/artifactregistry.reader` plus logging and monitoring writer roles, so nodes can pull your images.
   (GKE Autopilot is the alternative: less to manage and billed per pod, but you lose the node-level exercises like draining a node. Try Standard first.)
2. Install `gke-gcloud-auth-plugin`, run `gcloud container clusters get-credentials`, then learn `kubectl`
   (get, describe, logs, exec, port-forward, rollout).
3. Package the app as a **Helm chart** (or Kustomize base + overlays): Deployments for backend and frontend, Services, ConfigMaps, Secrets.
4. Kafka with the **Strimzi operator** (KRaft node pools), a `KafkaConnect` and a `KafkaConnector` resource for the JDBC sink.
5. PostgreSQL as a StatefulSet with a PVC (GKE provisions a Persistent Disk; look at the StorageClass). Later, compare it with Cloud SQL for PostgreSQL.
6. Probes: use `/api/actuator/health/liveness` and `/readiness` (already in the backend). Add resource requests/limits and an HPA.
7. Exposure: use GKE's built-in Ingress or the Gateway API (GKE has a native Gateway controller). Either one creates a Google Cloud load balancer that bills
   while it exists, so include it in your teardown. If you consider `ingress-nginx`, first check its current status: the Kubernetes project announced its retirement.

**Cost note:** the cluster is your biggest expense. Check the Google Cloud pricing calculator for your node type, and treat the cluster like a lab
session resource: create it, work, destroy it. Do not leave it running overnight.

**Break it:** delete a pod, drain a node, set a wrong image tag, exhaust memory, break a readiness probe, and diagnose each with `kubectl`.
Remove the reader role from the node service account and watch `ImagePullBackOff` appear.

**You're done when:** the UI works through a public address and an order flows through the pipeline inside the cluster.

---

## Phase 8: CD, monitoring, rollback

- Add a deploy stage to Jenkins: `helm upgrade --install --atomic` with the image tag from the build.
- Install Prometheus and Grafana (kube-prometheus-stack); expose Spring Boot metrics (add the Micrometer Prometheus registry) and Kafka lag.
  Then compare with Google Cloud Managed Service for Prometheus and Cloud Monitoring, and note what each costs you in effort and money.
- Do a **rollback drill**: ship a bad version on purpose, watch probes stop the rollout, and `helm rollback`.
- Secrets done properly: keep them in **Secret Manager** and sync them into Kubernetes (External Secrets Operator or the Secret Manager CSI driver).
- Keyless access from pods: set up **Workload Identity Federation for GKE**, so a pod acts as a Google service account without any key file.
- Capstone: write a runbook (`docs/runbook.md`) and a 10-minute demo of the whole flow, from `git push` to a running order.