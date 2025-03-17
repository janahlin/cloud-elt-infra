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