variable "cloud_provider" {
  description = "Cloud provider (azure or oci)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# OCI specific variables
variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
  default     = ""
}

variable "object_storage_namespace" {
  description = "OCI Object Storage Namespace"
  type        = string
  default     = ""
}

# Azure specific variables
variable "location" {
  description = "Azure region"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "storage_tier" {
  description = "Storage tier/SKU"
  type        = string
  default     = "Standard_LRS"
}

# Outputs
output "bucket_name" {
  description = "Name of the created storage bucket/container"
  value       = var.cloud_provider == "oci" ? oci_objectstorage_bucket.bucket[0].name : (
    var.cloud_provider == "azure" ? azurerm_storage_container.container[0].name : null
  )
}

output "storage_account_id" {
  description = "ID of the Azure Storage Account"
  value       = var.cloud_provider == "azure" ? azurerm_storage_account.storage[0].id : null
}

# OCI Resources
resource "oci_objectstorage_bucket" "bucket" {
  count          = var.cloud_provider == "oci" ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.resource_prefix}-${var.environment}-bucket"
  namespace      = var.object_storage_namespace
  
  # Free Tier settings
  storage_tier   = "Standard"      # Standard tier is included in free tier
  versioning     = "Disabled"      # Disable versioning to save space
  auto_tiering   = "Disabled"      # Disable auto-tiering to maintain free tier eligibility
  
  # Add optional lifecycle policy for free tier optimization
  # This can help manage storage usage to stay within free tier limits
  object_lifecycle_policy_etag = oci_objectstorage_object_lifecycle_policy.lifecycle_policy[0].etag
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
    time_amount = 30
    time_unit   = "DAYS"
  }
}

# Azure Resources
resource "azurerm_storage_account" "storage" {
  count                    = var.cloud_provider == "azure" ? 1 : 0
  name                     = "${var.resource_prefix}${var.environment}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Use LRS (Locally Redundant Storage) for free tier
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    delete_retention_policy {
      days = 7 # Minimum required retention for free tier
    }
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_container" "container" {
  count                 = var.cloud_provider == "azure" ? 1 : 0
  name                  = "${var.resource_prefix}-${var.environment}-container"
  storage_account_name  = azurerm_storage_account.storage[0].name
  container_access_type = "private"
}