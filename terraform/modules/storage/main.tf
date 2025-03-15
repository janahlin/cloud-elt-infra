resource "azurerm_storage_account" "storage" {
  name                     = "eltstorageaccount"
  resource_group_name      = "elt-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}