variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "zone" {
  type    = string
  default = "asia-south1-a"
}

variable "allowed_ssh_ip" {
  description = "Your current public IP in CIDR form, e.g. 49.36.1.2/32. Get it with: curl -s ifconfig.me"
  type        = string
}

variable "ssh_public_key" {
  description = "Contents of your public SSH key file (~/.ssh/id_ed25519.pub)."
  type        = string
}

variable "ssh_user" {
  description = "Your Linux username, used for SSH into the VM."
  type        = string
}
