module "network" {
  source = "./modules/network"

  network_name            = var.environment
  location                = var.location
  resource_group_name     = var.resource_group_name
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
  tags                    = var.tags
}

module "registry" {
  source = "./modules/registry"

  container_registry_name_prefix = "acr"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  sku                            = var.acr_sku
  tags                           = var.tags
}

module "vm" {
  source = "./modules/vm"

  vm_name             = "${var.environment}-vm01"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.subnet_id
  admin_username      = var.admin_username
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  vm_size             = var.vm_size
  tags                = var.tags
}

module "jenkins_vm" {
  source = "./modules/vm"

  vm_name = "${var.environment}-jenkins-vm01"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.subnet_id
  admin_username      = var.admin_username
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  vm_size             = var.vm_size
  tags                = var.tags
}

# module "jenkins_agent" {
#   source = "./modules/vm"

#   vm_name             = "${var.environment}-jenkins-agent"
#   location            = "West India"
#   resource_group_name = var.resource_group_name
#   subnet_id           = module.network.subnet_id
#   admin_username      = var.admin_username
#   ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
#   vm_size             = var.vm_size
#   tags                = var.tags
# }

