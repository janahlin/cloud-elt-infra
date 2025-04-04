locals {
  # Ensure environment tag value is truncated to Azure's 256-character limit
  # First, convert to string to handle any non-string values
  environment_str = tostring(var.environment)
  # Then truncate to 256 characters
  environment_tag = substr(local.environment_str, 0, min(256, length(local.environment_str)))

  # Common tags to be used across all Azure resources
  common_tags = {
    Environment = local.environment_tag
    ManagedBy   = "Terraform"
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

output "common_tags" {
  description = "Common tags to be used across all Azure resources"
  value       = local.common_tags
}
