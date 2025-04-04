output "storage_account_name" {
  description = "The name of the storage account"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.storage[0].name : null
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.storage[0].id : null
}

output "container_name" {
  description = "The name of the Azure storage container"
  value       = var.cloud_provider == "azure" ? azurerm_storage_container.container[0].name : null
}

output "bucket_name" {
  description = "The name of the OCI bucket"
  value       = var.cloud_provider == "oci" ? oci_objectstorage_bucket.bucket[0].name : null
}

output "bucket_namespace" {
  description = "The namespace of the OCI bucket"
  value       = var.cloud_provider == "oci" ? var.object_storage_namespace : null
}
