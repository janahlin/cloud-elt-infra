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
  description = "OCI API Key Fingerprint"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oci_private_key_path" {
  description = "Path to OCI API private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "oci_region" {
  description = "OCI region for resources"
  type        = string
  default     = "us-ashburn-1"
}

variable "compute_shape" {
  description = "OCI compute shape"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Storage configuration
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

# Compute configuration
variable "oci_compute_ocpus" {
  description = "Number of OCPUs for OCI compute instances"
  type        = number
  default     = 1
}

variable "oci_compute_memory_gb" {
  description = "Memory in GB for OCI compute instances"
  type        = number
  default     = 1
}

# Databricks configuration
variable "databricks_docker_port" {
  description = "Port for Databricks Docker container"
  type        = number
  default     = 8443
}

variable "databricks_docker_image" {
  description = "Docker image for Databricks"
  type        = string
  default     = "databricks/community-edition"
}

# Monitoring configuration
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "alert_email_addresses" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}