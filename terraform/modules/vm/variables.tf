variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  description = "Specific zone within the region, e.g. asia-south1-a."
  type        = string
}

variable "name" {
  type    = string
  default = "jenkins-vm"
}

variable "machine_type" {
  description = "e2-micro is too small for Jenkins + Docker + Maven builds; e2-medium is the practical minimum."
  type        = string
  default     = "e2-medium"
}

variable "subnet_self_link" {
  type = string
}

variable "ssh_public_key" {
  description = "Contents of your ~/.ssh/id_ed25519.pub (or similar). Used for OS Login-free key-based SSH."
  type        = string
}

variable "ssh_user" {
  description = "Username that owns the SSH key above; used to build the 'ssh-keys' metadata entry."
  type        = string
}

variable "registry_reader_role" {
  description = "IAM role granted to this VM's service account so it can push to Artifact Registry."
  type        = string
  default     = "roles/artifactregistry.writer"
}
