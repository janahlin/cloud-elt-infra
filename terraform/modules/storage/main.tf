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
}

# Azure Resources
resource "azurerm_storage_account" "storage" {
  count                    = var.cloud_provider == "azure" ? 1 : 0
  name                     = "${var.resource_prefix}${var.environment}sa"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = split("_", var.storage_tier)[0]
  account_replication_type = split("_", var.storage_tier)[1]
}

resource "azurerm_storage_container" "container" {
  count                 = var.cloud_provider == "azure" ? 1 : 0
  name                  = "${var.resource_prefix}-${var.environment}-container"
  storage_account_name  = azurerm_storage_account.storage[0].name
  container_access_type = "private"
}