provider "google" {
  project = var.project_id
  region  = var.region
}

# The APIs every later module needs. Enabling them here means you hit this error class
# exactly once, in one place, instead of module by module later.
locals {
  required_apis = [
    "compute.googleapis.com",             # VMs, networks, firewall rules
    "container.googleapis.com",           # GKE (Phase 7)
    "artifactregistry.googleapis.com",    # Docker image registry (Phase 6)
    "iam.googleapis.com",                 # service accounts
    "cloudresourcemanager.googleapis.com",# project-level operations Terraform needs internally
    "secretmanager.googleapis.com",       # Phase 8
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)
  project  = var.project_id
  service  = each.value

  # Leave the API enabled if this resource is ever removed from state; disabling an API
  # out from under a running project is rarely what you want.
  disable_on_destroy = false
}

# Versioning matters here: if state ever gets corrupted, an old version can save you.
# The gcs backend uses this same bucket for locking, so no separate DynamoDB-style
# lock table is needed, unlike AWS.
resource "google_storage_bucket" "tf_state" {
  name          = "${var.project_id}-tfstate-${var.state_bucket_suffix}"
  project       = var.project_id
  location      = var.region
  force_destroy = false # a safety rail: `terraform destroy` on THIS bucket should be deliberate, not accidental

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  depends_on = [google_project_service.apis]
}
