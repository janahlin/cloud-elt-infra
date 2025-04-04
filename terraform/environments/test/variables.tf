# Common variables
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC/VNet"
  type        = string
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
}

# Azure specific variables
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
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
  sensitive   = true
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "storage_tier" {
  description = "Storage tier to use"
  type        = string
}

variable "databricks_sku" {
  description = "The SKU for Azure Databricks"
  type        = string
}

variable "vm_size" {
  description = "The size of VM to use in Azure"
  type        = string
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
