resource "azurerm_virtual_network" "vnet" {
  name                = "elt-vnet"
  location            = "East US"
  resource_group_name = "elt-rg"
  address_space       = ["10.0.0.0/16"]
}