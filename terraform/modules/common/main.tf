# Common module main configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Configure providers based on cloud_provider variable
provider "azurerm" {
  features {}
  skip_provider_registration = true
  count                      = var.cloud_provider == "azure" ? 1 : 0
}

provider "oci" {
  count = var.cloud_provider == "oci" ? 1 : 0
}

# Common resource naming
locals {
  resource_name = "${var.resource_prefix}-${var.environment}"

  # Common tags for both Azure and OCI
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Cloud ELT Infrastructure"
  }
}
