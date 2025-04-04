# Common module main configuration

terraform {
  required_version = ">= 1.0"
}

# Common resource naming
locals {
  # Common tags for both Azure and OCI
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Cloud ELT Infrastructure"
    Prefix      = var.resource_prefix
  }
}
