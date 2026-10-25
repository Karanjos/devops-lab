locals {
  storage_account_name = substr("${var.storage_account_name_prefix}${random_string.suffix.result}", 0, 24)
}