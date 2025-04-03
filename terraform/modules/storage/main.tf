# Define locals for provider checks
locals {
  is_azure = var.cloud_provider == "azure"
  is_oci   = var.cloud_provider == "oci"
}

# OCI Resources
resource "oci_objectstorage_bucket" "bucket" {
  count          = var.cloud_provider == "oci" ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.resource_prefix}-${var.environment}-bucket"
  namespace      = var.object_storage_namespace
  
  # Storage settings
  storage_tier   = var.oci_storage_tier
  versioning     = var.oci_storage_versioning
  auto_tiering   = var.oci_storage_auto_tiering
}

# Lifecycle policy to automatically clean up older objects
resource "oci_objectstorage_object_lifecycle_policy" "lifecycle_policy" {
  count        = var.cloud_provider == "oci" ? 1 : 0
  bucket       = oci_objectstorage_bucket.bucket[0].name
  namespace    = var.object_storage_namespace
  
  rules {
    action      = "DELETE"
    is_enabled  = true
    name        = "delete-old-objects"
    time_amount = var.oci_storage_lifecycle_days
    time_unit   = "DAYS"
  }
}

# Azure Resources
resource "azurerm_storage_account" "storage" {
  count                    = var.cloud_provider == "azure" ? 1 : 0
  name                     = "${var.resource_prefix}${var.environment}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.azure_storage_account_tier
  account_replication_type = "LRS"
  min_tls_version          = var.azure_storage_min_tls_version
}

resource "azurerm_storage_container" "container" {
  count                 = var.cloud_provider == "azure" ? 1 : 0
  name                  = "${var.resource_prefix}-${var.environment}-container"
  storage_account_name  = azurerm_storage_account.storage[0].name
  container_access_type = var.azure_storage_container_access_type
}