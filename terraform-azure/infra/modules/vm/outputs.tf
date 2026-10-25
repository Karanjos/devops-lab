output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "principal_id" {
  value = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}