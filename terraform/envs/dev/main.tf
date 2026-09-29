provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source = "../../modules/network"

  project_id     = var.project_id
  region         = var.region
  allowed_ssh_ip = var.allowed_ssh_ip
}

module "registry" {
  source = "../../modules/registry"

  project_id = var.project_id
  region     = var.region
}

module "vm" {
  source = "../../modules/vm"

  project_id       = var.project_id
  region           = var.region
  zone             = var.zone
  subnet_self_link = module.network.subnet_self_link
  ssh_public_key   = var.ssh_public_key
  ssh_user         = var.ssh_user
}
