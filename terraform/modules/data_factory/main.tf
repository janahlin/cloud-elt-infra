resource "azurerm_data_factory" "data_factory" {
  name                = "elt-datafactory"
  location            = "East US"
  resource_group_name = "elt-rg"
}