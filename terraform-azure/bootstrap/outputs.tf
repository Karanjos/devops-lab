output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_container_name" {
  value = azurerm_storage_container.storage_container.name
}

output "backend_configuration" {
  value = <<-EOT
    terraform{
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.rg.name}"
        storage_account_name = "${azurerm_storage_account.storage_account.name}"
        container_name       = "${azurerm_storage_container.storage_container.name}"
        key                  = "tfstate/terraform.tfstate"
        use_azuread_auth     = true
      }
    }
  EOT
}