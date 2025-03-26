variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 3
}

variable "storage_tier" {
  description = "The tier of storage to use"
  type        = string
  default     = "Standard_LRS"
}

variable "databricks_sku" {
  description = "The SKU for Azure Databricks"
  type        = string
  default     = "premium"
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_D4s_v3"
}

# New monitoring variables
variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "alert_email_addresses" {
  description = "List of email addresses for monitoring alerts"
  type        = list(string)
  default     = []
}