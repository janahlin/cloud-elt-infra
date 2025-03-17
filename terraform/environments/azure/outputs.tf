output "resource_group_name" {
  description = "Azure Resource Group Name"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.rg.id
}

output "vnet_id" {
  description = "Azure VNet ID"
  value       = module.networking.vnet_id
}

output "subnet_ids" {
  description = "Azure Subnet IDs"
  value       = module.networking.subnet_ids
}

output "storage_account_name" {
  description = "Azure Storage Account Name"
  value       = module.storage.storage_account_id
}

output "databricks_workspace_url" {
  description = "URL for Databricks workspace"
  value       = module.databricks.databricks_workspace_url
}

output "data_factory_name" {
  description = "Name of the Azure Data Factory"
  value       = module.data_factory.data_factory_name
}

output "data_factory_id" {
  description = "ID of the Azure Data Factory"
  value       = module.data_factory.data_factory_id
}