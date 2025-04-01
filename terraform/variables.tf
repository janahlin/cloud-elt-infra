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
  description = "Azure Client ID (leave empty to use managed identity)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret (leave empty to use managed identity)"
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
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "storage_tier" {
  description = "Storage tier to use (for both Azure and OCI)"
  type        = string
  default     = "Standard_LRS"  # Most economical storage option for Azure
}

variable "databricks_sku" {
  description = "The SKU for Azure Databricks"
  type        = string
  default     = "standard"  # Standard tier is more economical than premium
}

variable "vm_size" {
  description = "The size of VM to use in Azure"
  type        = string
  default     = "Standard_B1s"  # Free tier eligible VM size
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
  description = "OCI region for resources"
  type        = string
  default     = "us-ashburn-1"
}

variable "oci_compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = ""
}

variable "compute_shape" {
  description = "The shape of compute instances in OCI"
  type        = string
  default     = "VM.Standard.E2.1.Micro"  # Always Free Tier eligible
}

# SSH Keys for OCI compute
variable "ssh_public_key" {
  description = "SSH public key for OCI compute instances"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for OCI compute instances"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Monitoring configuration
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "alert_email_addresses" {
  description = "Email addresses to send alerts to"
  type        = list(string)
  default     = []
}