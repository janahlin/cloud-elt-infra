# Common variables
variable "cloud_provider" {
  description = "Cloud provider to use (azure or oci)"
  type        = string
  default     = "azure"
  
  validation {
    condition     = contains(["azure", "oci"], var.cloud_provider)
    error_message = "The cloud_provider value must be either 'azure' or 'oci'."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be 'dev', 'staging', or 'prod'."
  }
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "elt"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC/VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 3
}

# Azure specific variables
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "storage_tier" {
  description = "Azure storage tier"
  type        = string
  default     = "Standard_LRS"
}

variable "databricks_sku" {
  description = "Databricks SKU"
  type        = string
  default     = "premium"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D4s_v3"
}

# OCI specific variables
variable "oci_tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oci_user_ocid" {
  description = "OCI User OCID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oci_fingerprint" {
  description = "OCI API Key fingerprint"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oci_private_key_path" {
  description = "Path to the OCI API private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "oci_region" {
  description = "OCI Region"
  type        = string
  default     = "us-ashburn-1"
}

variable "oci_compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = ""
}

variable "compute_shape" {
  description = "OCI compute shape"
  type        = string
  default     = "VM.Standard.E4.Flex"
}