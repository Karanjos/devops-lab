variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for the backend"
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  type    = string
  default = "COMMON_DEV-RESOURCE_GROUP"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10:40.0.0/16"]
}

variable "subnet_address_prefixes" {
  type    = list(string)
  default = ["10.40.1.0/24"]
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Local path to SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "acr_sku" {
  type    = string
  default = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "tags" {
  type = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    workload    = "devops-lab"
  }
}