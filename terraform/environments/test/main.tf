provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id

  # Only include client_id and client_secret if using Service Principal auth
  client_id     = var.azure_client_id != "" ? var.azure_client_id : null
  client_secret = var.azure_client_secret != "" ? var.azure_client_secret : null
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-${var.environment}-rg"
  location = var.location
}

module "networking" {
  source              = "../../modules/networking"
  cloud_provider      = "azure"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vpc_cidr            = var.vpc_cidr
  subnet_count        = var.subnet_count
}

module "storage" {
  source              = "../../modules/storage"
  cloud_provider      = "azure"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_tier        = var.storage_tier
}

module "databricks" {
  source              = "../../modules/databricks"
  cloud_provider      = "azure"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.networking.subnet_ids[0]
  databricks_sku      = var.databricks_sku
}

module "data_factory" {
  source              = "../../modules/data_factory"
  cloud_provider      = "azure"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "compute" {
  source              = "../../modules/compute"
  cloud_provider      = "azure"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = var.vm_size
  subnet_id           = module.networking.subnet_ids[2]
}

# New monitoring module
module "monitoring" {
  source                = "../../modules/monitoring"
  cloud_provider        = "azure"
  environment           = var.environment
  resource_prefix       = var.resource_prefix
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  compute_resource_id   = module.compute.instance_id
  log_retention_days    = var.log_retention_days
  alert_email_addresses = var.alert_email_addresses
}
