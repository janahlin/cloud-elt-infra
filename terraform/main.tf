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
  tenancy_ocid     = var.cloud_provider == "oci" ? var.oci_tenancy_ocid : ""
  user_ocid        = var.cloud_provider == "oci" ? var.oci_user_ocid : ""
  fingerprint      = var.cloud_provider == "oci" ? var.oci_fingerprint : ""
  private_key_path = var.cloud_provider == "oci" ? var.oci_private_key_path : ""
  region           = var.cloud_provider == "oci" ? var.oci_region : ""
}

# Configure Azure provider with Service Principal
provider "azurerm" {
  features {}
  subscription_id            = var.azure_subscription_id
  client_id                  = var.azure_client_id
  client_secret              = var.azure_client_secret
  tenant_id                  = var.azure_tenant_id
  skip_provider_registration = var.cloud_provider != "azure"
}

# Create a map for conditional module deployment
locals {
  # Using a simple map with a single key to ensure the module is created only once
  deploy_azure = var.cloud_provider == "azure" ? toset(["azure"]) : toset([])
  deploy_oci   = var.cloud_provider == "oci" ? toset(["oci"]) : toset([])
}

# Deploy Azure environment if selected
module "azure_environment" {
  source   = "./environments/azure"
  for_each = local.deploy_azure

  # Common variables
  environment     = var.environment
  resource_prefix = var.resource_prefix
  vpc_cidr        = var.vpc_cidr
  subnet_count    = var.subnet_count

  # Azure specific variables
  azure_subscription_id = var.azure_subscription_id
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id
  location              = var.azure_location
  storage_tier          = var.storage_tier
  databricks_sku        = var.databricks_sku
  vm_size               = var.vm_size

  # These variables are used by the monitoring module
  log_retention_days    = try(var.log_retention_days, 30)
  alert_email_addresses = try([var.alert_email_addresses], [])
}

# Deploy OCI environment if selected
module "oci_environment" {
  source   = "./environments/oci"
  for_each = local.deploy_oci

  # Common variables
  environment     = var.environment
  resource_prefix = var.resource_prefix
  vpc_cidr        = var.vpc_cidr
  subnet_count    = var.subnet_count

  # OCI specific variables
  oci_tenancy_ocid     = var.oci_tenancy_ocid
  oci_user_ocid        = var.oci_user_ocid
  oci_fingerprint      = var.oci_fingerprint
  oci_private_key_path = var.oci_private_key_path
  oci_region           = var.oci_region
  compute_shape        = var.compute_shape
  ssh_public_key       = var.ssh_public_key
  ssh_private_key_path = var.ssh_private_key_path

  # These variables are used by the monitoring module
  log_retention_days    = try(var.log_retention_days, 30)
  alert_email_addresses = try([var.alert_email_addresses], [])
}
