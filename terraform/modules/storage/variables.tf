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

variable "storage_tier" {
  description = "Storage tier"
  type        = string
  default     = "Standard_LRS"
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

variable "azure_storage_account_tier" {
  description = "Azure storage account tier"
  type        = string
  default     = "Standard"
}

variable "azure_storage_min_tls_version" {
  description = "Minimum TLS version for Azure storage"
  type        = string
  default     = "TLS1_2"
}

variable "azure_storage_container_access_type" {
  description = "Access type for Azure storage container"
  type        = string
  default     = "private"
}

# OCI specific variables
variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = ""
}

variable "object_storage_namespace" {
  description = "OCI Object Storage namespace"
  type        = string
  default     = ""
}

variable "oci_storage_tier" {
  description = "OCI object storage tier"
  type        = string
  default     = "Standard"
}

variable "oci_storage_versioning" {
  description = "Enable OCI object storage versioning"
  type        = string
  default     = "Disabled"
}

variable "oci_storage_auto_tiering" {
  description = "Enable OCI object storage auto-tiering"
  type        = string
  default     = "Disabled"
}

variable "oci_storage_lifecycle_days" {
  description = "Number of days before objects are deleted in OCI storage"
  type        = number
  default     = 30
}
