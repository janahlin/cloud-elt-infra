output "storage_account_name" {
  description = "The name of the storage account"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.storage[0].name : null
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.storage[0].id : null
}

output "data_container_name" {
  description = "The name of the data container"
  value       = var.cloud_provider == "azure" ? azurerm_storage_container.data[0].name : null
}

output "logs_container_name" {
  description = "The name of the logs container"
  value       = var.cloud_provider == "azure" ? azurerm_storage_container.logs[0].name : null
}

output "data_bucket_name" {
  description = "The name of the data bucket"
  value       = var.cloud_provider == "oci" ? oci_objectstorage_bucket.data_bucket[0].name : null
}

output "logs_bucket_name" {
  description = "The name of the logs bucket"
  value       = var.cloud_provider == "oci" ? oci_objectstorage_bucket.logs_bucket[0].name : null
}