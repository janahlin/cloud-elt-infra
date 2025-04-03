# Common outputs
output "cloud_provider" {
  description = "Cloud provider used for deployment"
  value       = var.cloud_provider
}

output "environment" {
  description = "Environment used for deployment"
  value       = var.environment
}

# Create locals to simplify conditional output values
locals {
  # Azure outputs (only available if using Azure)
  azure_outputs = var.cloud_provider == "azure" ? {
    resource_group_name     = try(module.azure_environment["azure"].resource_group_name, null)
    vnet_id                 = try(module.azure_environment["azure"].vnet_id, null)
    storage_account_name    = try(module.azure_environment["azure"].storage_account_name, null)
    databricks_workspace_url = try(module.azure_environment["azure"].databricks_workspace_url, null)
    data_factory_name       = try(module.azure_environment["azure"].data_factory_name, null)
  } : {}
  
  # OCI outputs (only available if using OCI)
  oci_outputs = var.cloud_provider == "oci" ? {
    compartment_id          = try(module.oci_environment["oci"].compartment_id, null)
    compartment_name        = try(module.oci_environment["oci"].compartment_name, null)
    object_storage_namespace = try(module.oci_environment["oci"].object_storage_namespace, null)
    vcn_id                  = try(module.oci_environment["oci"].vcn_id, null)
    bucket_name             = try(module.oci_environment["oci"].bucket_name, null)
    databricks_url          = try(module.oci_environment["oci"].databricks_url, null)
    airflow_url             = try(module.oci_environment["oci"].airflow_url, null)
  } : {}
}

# Consolidated outputs
output "deployed_infrastructure" {
  description = "Details of the deployed infrastructure"
  value = var.cloud_provider == "azure" ? {
    provider             = "Azure"
    environment          = var.environment
    resource_group       = try(local.azure_outputs.resource_group_name, null)
    storage_account      = try(local.azure_outputs.storage_account_name, null)
    databricks_workspace = try(local.azure_outputs.databricks_workspace_url, null)
    data_factory_name    = try(local.azure_outputs.data_factory_name, null)
  } : {
    provider           = "OCI"
    environment        = var.environment
    compartment        = try(local.oci_outputs.compartment_name, null)
    object_storage     = try(local.oci_outputs.object_storage_namespace, null)
    airflow_url        = try(local.oci_outputs.airflow_url, null)
    databricks_url     = try(local.oci_outputs.databricks_url, null)
  }
}

output "connection_details" {
  description = "Connection information for deployed services"
  value = var.cloud_provider == "azure" ? {
    databricks_host = try(local.azure_outputs.databricks_workspace_url, null)
    storage_account = try(local.azure_outputs.storage_account_name, null)
  } : {
    databricks_host = try(local.oci_outputs.databricks_url, null)
    object_storage  = try(local.oci_outputs.object_storage_namespace, null)
    airflow_url     = try(local.oci_outputs.airflow_url, null)
  }
  sensitive = true
}

# OCI specific outputs
output "oci_compartment_id" {
  description = "OCI Compartment ID"
  value       = try(local.oci_outputs.compartment_id, null)
}

output "oci_vcn_id" {
  description = "OCI VCN ID"
  value       = try(local.oci_outputs.vcn_id, null)
}

output "oci_bucket_name" {
  description = "OCI Object Storage Bucket Name"
  value       = try(local.oci_outputs.bucket_name, null)
}

output "oci_databricks_url" {
  description = "OCI Databricks URL"
  value       = try(local.oci_outputs.databricks_url, null)
}

output "oci_airflow_url" {
  description = "OCI Airflow URL"
  value       = try(local.oci_outputs.airflow_url, null)
}

# Azure specific outputs
output "azure_resource_group_name" {
  description = "Azure Resource Group Name"
  value       = try(local.azure_outputs.resource_group_name, null)
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = try(local.azure_outputs.vnet_id, null)
}

output "azure_storage_account_name" {
  description = "Azure Storage Account Name"
  value       = try(local.azure_outputs.storage_account_name, null)
}

output "azure_databricks_workspace_url" {
  description = "Azure Databricks Workspace URL"
  value       = try(local.azure_outputs.databricks_workspace_url, null)
}

output "azure_data_factory_name" {
  description = "Azure Data Factory Name"
  value       = try(local.azure_outputs.data_factory_name, null)
}