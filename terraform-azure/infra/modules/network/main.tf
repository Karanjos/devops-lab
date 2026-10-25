resource "azurerm_virtual_network" "vnet"{
  name  = "${var.network_name}-vnet"
  location = var.location
  address_space = var.vnet_address_space
  resource_group_name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.network_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_network_security_group" "nsg" {
  name = "${var.network_name}-nsg"
  location = var.location
  resource_group_name= var.resource_group_name

  # VM is public and should be accessed through allowed ips only.
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}






