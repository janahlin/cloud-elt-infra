resource "azurerm_databricks_workspace" "databricks" {
  name                = "elt-databricks"
  location            = "East US"
  resource_group_name = "elt-rg"
  sku                 = "standard"
}