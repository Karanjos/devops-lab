terraform{
  backend "azurerm" {
    resource_group_name  = "COMMON_DEV-RESOURCE_GROUP"
    storage_account_name = "commondevstorageaccountd"
    container_name       = "common-dev-container"
    key                  = "tfstate/terraform.tfstate"
    use_azuread_auth     = true
  }
}