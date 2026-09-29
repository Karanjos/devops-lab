# Phase 4: Terraform on GCP

This guide assumes the code in `terraform/` (bootstrap, modules, envs/dev) is already in your
repo. Follow it top to bottom the first time; skip to a section once you know it.

## 0. Manual setup (do this once, in the browser and gcloud, not in Terraform)

1. **Activate the $300 trial credit** at console.cloud.google.com if you haven't already.
2. **Create a project just for this lab**: `devops-lab-<yourname>` or similar. Note its exact
   **project ID** (not its display name — check the dropdown at the top of the console).
3. **Set budget alerts**: Billing → Budgets & alerts → create one at $25, $100, $200. These
   only email you; they never stop spending on their own.
4. **Install the tools**, inside your WSL Ubuntu:
   ```bash
   # gcloud
   curl -sSL https://sdk.cloud.google.com | bash
   exec -l $SHELL   # reload your shell so `gcloud` is on PATH

   # terraform
   sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install -y terraform
   terraform version
   ```
5. **Authenticate**:
   ```bash
   gcloud auth login
   gcloud auth application-default login   # this is the credential Terraform actually uses
   gcloud config set project <your-project-id>
   gcloud config set compute/region asia-south1
   ```
6. **Generate an SSH key**, if you don't already have one (you'll need this for the VM module):
   ```bash
   ssh-keygen -t ed25519 -C "devops-lab" -f ~/.ssh/devops_lab_ed25519
   cat ~/.ssh/devops_lab_ed25519.pub
   ```
7. **Find your public IP**, for the firewall rules:
   ```bash
   curl -s ifconfig.me
   ```
   If your ISP changes it later (common on home broadband), firewall rules will start
   rejecting your SSH, and you'll need to re-apply with the new IP. That's expected, not a bug.

## 1. Bootstrap: create the state bucket

Run this once per project. It has its own local state (see `terraform/bootstrap/README.md`
for why).

```bash
cd terraform/bootstrap
terraform init
terraform plan -var="project_id=<your-project-id>" -var="state_bucket_suffix=$(openssl rand -hex 3)"
terraform apply -var="project_id=<your-project-id>" -var="state_bucket_suffix=$(openssl rand -hex 3)"
```
Copy the `state_bucket_name` output. You'll need it in the next step.

**Save your exact variable values somewhere** (a `NOTES.md`, or export them as shell
variables), since bootstrap has no `.tfvars` file and you'll want the same suffix if you ever
re-run it.

## 2. Point envs/dev at that bucket

```bash
cd ../envs/dev
```
Edit `backend.tf`, replacing the placeholder with your real bucket name from step 1:
```hcl
backend "gcs" {
  bucket = "devops-lab-yourname-tfstate-a1b2c3"
  prefix = "envs/dev"
}
```

Copy the tfvars example and fill it in:
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`:
- `project_id`: your real project ID
- `allowed_ssh_ip`: output of `curl -s ifconfig.me`, with `/32` appended
- `ssh_user`: your Linux username (`whoami`)
- `ssh_public_key`: contents of `~/.ssh/devops_lab_ed25519.pub`

## 3. Init, plan, apply

```bash
terraform init
terraform fmt -check      # style check; run `terraform fmt` (no -check) to auto-fix
terraform validate        # catches syntax/type errors before touching GCP
terraform plan -out=tfplan
```
Read the plan output carefully before applying. It should show resources being **created**,
never destroyed, on a first run. Count them: 1 VPC, 1 subnet, 2 firewall rules, 1 router, 1
NAT, 1 Artifact Registry repo, 1 service account, 1 IAM binding, 1 static IP, 1 VM. If the
count looks very different from that, stop and read why before applying.

```bash
terraform apply tfplan
```

## 4. Confirm it worked

```bash
terraform output
gcloud compute instances list
```

SSH into the VM using the key you generated:
```bash
ssh -i ~/.ssh/devops_lab_ed25519 <ssh_user>@$(terraform output -raw jenkins_vm_ip)
```
If this hangs rather than refusing outright, your IP probably changed since you set
`allowed_ssh_ip`. Re-check `curl -s ifconfig.me`, update `terraform.tfvars`, and re-apply.

Confirm the VM can push to Artifact Registry (it can't build/push anything yet — Phase 6 does
that — but you can confirm the *permission* exists):
```bash
gcloud projects get-iam-policy <your-project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(terraform output -raw vm_service_account)"
```
You should see `roles/artifactregistry.writer` listed.

## 5. Break it (do these deliberately, one at a time)

**Drift detection.** In the Cloud Console, manually delete the Jenkins firewall rule (Compute
Engine → Firewall). Then:
```bash
terraform plan
```
Terraform should show it wants to *recreate* the missing rule. This is what "drift" looks
like: Terraform's state says a resource exists, but reality disagrees. Apply to fix it.

**State lock.** Start an `apply`, and while it's running (mid-plan is fine), open a second
terminal in the same folder and run `terraform plan` again. It should refuse, reporting the
state is locked. This is the GCS backend's built-in locking working as intended, it's exactly
what stops two people (or two Jenkins jobs, later) from corrupting state by running at the
same time.

**Renaming a resource.** In `terraform/modules/vm/main.tf`, rename the VM resource itself:
```hcl
resource "google_compute_instance" "vm" {       # change "vm" to "jenkins"
```
```bash
terraform plan
```
Terraform will propose destroying the old one and creating a new one with the same
configuration, since as far as it's concerned, `google_compute_instance.vm` is gone and
`google_compute_instance.jenkins` is new, even though nothing about the actual VM changed.
Fix it properly with a `moved` block instead of applying the destroy/recreate:
```hcl
moved {
  from = google_compute_instance.vm
  to   = google_compute_instance.jenkins
}
```
Add that to `main.tf`, run `terraform plan` again, and confirm it now shows the resource being
renamed in-place, with no destroy/create.

**Missing API.** Comment out `"artifactregistry.googleapis.com"` from
`terraform/bootstrap/main.tf`'s `local.required_apis`, re-apply bootstrap, then try
`terraform apply` in envs/dev. Read the exact error GCP gives you when a resource needs an API
that isn't enabled. Put the line back and re-apply bootstrap.

**Interrupting an apply.** Start `terraform apply`, and press `Ctrl+C` partway through (after
it's started creating something, not right at the start). Run `terraform plan` afterward and
read how Terraform describes the partially-applied state. This is a good moment to appreciate
why state locking and small, reviewable plans matter.

## 6. Tear down

```bash
terraform destroy
```
Confirm with `gcloud compute instances list` that the VM is gone, and check the Cloud Console
billing page over the next day to confirm charges stopped accumulating.

The bootstrap bucket is deliberately **not** destroyed by this command (it lives in a
separate Terraform config with its own state). Leave it, you'll want it again next session. If
you ever want to remove it too:
```bash
cd ../../bootstrap
terraform destroy -var="project_id=<your-project-id>" -var="state_bucket_suffix=<your-suffix>"
```
Only do this if you're finished with the whole project, since destroying it deletes your
Terraform state history for envs/dev along with it.

## You're done when

- `terraform apply` in `envs/dev` builds everything from a clean checkout (delete
  `.terraform/` and re-run `terraform init` to prove this).
- `terraform destroy` removes every resource it created, and only those resources.
- You can explain, without looking it up: why bootstrap has local state but envs/dev has
  remote state, what the GCS backend gives you beyond "a place to put a file," and why the VM
  has its own service account instead of using the project's default one.
