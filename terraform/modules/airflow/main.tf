resource "azurerm_kubernetes_cluster" "airflow" {
  name                = "elt-airflow"
  location            = "East US"
  resource_group_name = "elt-rg"
  dns_prefix          = "airflowdns"
}