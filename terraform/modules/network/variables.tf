variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type    = string
  default = "devops-lab-vpc"
}

variable "subnet_cidr" {
  description = "Primary range for VM instances."
  type        = string
  default     = "10.10.0.0/24"
}

variable "gke_pods_cidr" {
  description = "Secondary range reserved now for GKE pod IPs (Phase 7). Creating it here avoids rebuilding the subnet later, since secondary ranges can't be added to an existing subnet in every case cleanly."
  type        = string
  default     = "10.20.0.0/16"
}

variable "gke_services_cidr" {
  description = "Secondary range reserved now for GKE service IPs (Phase 7)."
  type        = string
  default     = "10.30.0.0/20"
}

variable "allowed_ssh_ip" {
  description = "Your current public IP, in CIDR form (e.g. 1.2.3.4/32). Find it with: curl -s ifconfig.me. SSH and the Jenkins port are only opened to this address."
  type        = string
}
