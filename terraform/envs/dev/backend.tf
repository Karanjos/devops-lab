# Remote state: your laptop is no longer the only copy of "what exists." This is also what
# gives you locking (so two `apply`s can't run at once and corrupt state) and versioning
# (via the bucket's own versioning, turned on in bootstrap/main.tf).
#
# Fill in the bucket name AFTER running `terraform apply` in terraform/bootstrap/ once
# (its output is exactly what goes here).
terraform {
  backend "gcs" {
    bucket = "REPLACE-WITH-BOOTSTRAP-OUTPUT-state_bucket_name"
    prefix = "envs/dev"
  }
}
