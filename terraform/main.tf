# Root Terraform configuration
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 4.0"
    }
  }
  
  # Uncomment to use a remote backend
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "terraformstate"
  #   container_name       = "tfstate"
  #   key                  = "cloud-elt-infra.tfstate"
  # }
}

# Configure OCI provider if using OCI
provider "oci" {
  count           = var.cloud_provider == "oci" ? 1 : 0
  tenancy_ocid    = var.oci_tenancy_ocid
  user_ocid       = var.oci_user_ocid
  fingerprint     = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region          = var.oci_region
}

# Configure Azure provider if using Azure
provider "azurerm" {
  count           = var.cloud_provider == "azure" ? 1 : 0
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Route to appropriate environment based on cloud_provider variable
module "environment" {
  source = "./environments/${var.cloud_provider}"
  
  # Common variables
  environment      = var.environment
  resource_prefix  = var.resource_prefix
  vpc_cidr         = var.vpc_cidr
  subnet_count     = var.subnet_count
  
  # OCI specific variables (passed through only if OCI is selected)
  oci_tenancy_ocid  = var.oci_tenancy_ocid
  oci_user_ocid     = var.oci_user_ocid
  oci_fingerprint   = var.oci_fingerprint
  oci_private_key_path = var.oci_private_key_path
  oci_region        = var.oci_region
  
  # Azure specific variables (passed through only if Azure is selected)
  azure_subscription_id = var.azure_subscription_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id
  location              = var.azure_location
  storage_tier          = var.storage_tier
  databricks_sku        = var.databricks_sku
  vm_size               = var.vm_size
}