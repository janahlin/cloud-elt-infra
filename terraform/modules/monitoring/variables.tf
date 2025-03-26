variable "cloud_provider" {
  description = "The cloud provider to use (azure or oci)"
  type        = string
  validation {
    condition     = contains(["azure", "oci"], var.cloud_provider)
    error_message = "The cloud_provider value must be either 'azure' or 'oci'."
  }
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

# Azure-specific variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = ""
}

variable "compute_resource_id" {
  description = "Azure resource ID for compute resources to monitor"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

# OCI-specific variables
variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
  default     = ""
}

variable "notification_topic_ids" {
  description = "List of OCI notification topic OCIDs for alerts"
  type        = list(string)
  default     = []
}

# Common variables
variable "alert_email_addresses" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
} 