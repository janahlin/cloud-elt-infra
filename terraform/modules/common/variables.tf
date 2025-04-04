variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "cloud_provider" {
  description = "Cloud provider (azure, oci)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "oci"], var.cloud_provider)
    error_message = "Cloud provider must be one of: azure, oci"
  }
}

variable "resource_prefix" {
  description = "Prefix to be used for all resources"
  type        = string
  default     = "elt"
}

variable "location" {
  description = "Azure region or OCI region"
  type        = string
  default     = "westeurope" # Default for Azure
}
