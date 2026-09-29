# bootstrap/

Run this ONCE per GCP project, before anything else in terraform/envs/dev.

It creates the one thing envs/dev needs to even start: a GCS bucket to hold Terraform's
own state file. Because of that, this config's own state is kept LOCAL (on your machine,
in this folder), not remote. That's normal and correct for a bootstrap step: something has
to create the bucket before anything can use it as a backend.

It also enables the GCP APIs every later module needs, so you only do this once instead of
re-discovering "API not enabled" errors module by module.

Usage:
    cd terraform/bootstrap
    terraform init
    terraform apply -var="project_id=<your-project-id>"

Note the bucket name it outputs. You'll put it into terraform/envs/dev/backend.tf.

Do not delete terraform.tfstate in this folder once you've run it (it's git-ignored, as it
should be). If you lose it, Terraform will think the bucket doesn't exist and try to create
it again, which will just fail with "already exists" since it's still there in GCP. Recovery
in that case: `terraform import google_storage_bucket.tf_state <bucket-name>`.
