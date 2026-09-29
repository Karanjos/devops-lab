variable "project_id" {
  description = "The GCP project ID to bootstrap. Create this project by hand first (a lab-only project, so `terraform destroy` at the env level can never touch anything else)."
  type        = string
}

variable "region" {
  description = "Default region for the state bucket and enabled APIs."
  type        = string
  default     = "asia-south1" # Mumbai: widest service/machine availability from India
}

variable "state_bucket_suffix" {
  description = "Appended to the bucket name to keep it globally unique (GCS bucket names are global across ALL of GCP, not just your project)."
  type        = string
}
