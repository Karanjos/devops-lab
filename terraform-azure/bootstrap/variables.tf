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
  default = "rg-tfstate-shared"
}

variable "storage_account_name_prefix" {
  description = "Lowercase alphanumeric prefix; final name must be globally unique and 3-24 characters."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  type = map(string)
  default = {
    managed_by = "terraform"
    purpose    = "terraform-state"
  }
}