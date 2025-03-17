output "deployed_infrastructure" {
  description = "Details of the deployed infrastructure"
  value = var.cloud_provider == "azure" ? {
    provider             = "Azure"
    environment          = var.environment
    resource_group       = var.cloud_provider == "azure" ? module.environment.resource_group_name : null
    storage_account      = var.cloud_provider == "azure" ? module.environment.storage_account_name : null
    databricks_workspace = var.cloud_provider == "azure" ? module.environment.databricks_workspace_url : null
    data_factory_name    = var.cloud_provider == "azure" ? module.environment.data_factory_name : null
  } : {
    provider           = "OCI"
    environment        = var.environment
    compartment        = var.cloud_provider == "oci" ? module.environment.compartment_name : null
    object_storage     = var.cloud_provider == "oci" ? module.environment.object_storage_namespace : null
    airflow_url        = var.cloud_provider == "oci" ? module.environment.airflow_url : null
    databricks_url     = var.cloud_provider == "oci" ? module.environment.databricks_url : null
  }
}

output "connection_details" {
  description = "Connection information for deployed services"
  value = var.cloud_provider == "azure" ? {
    databricks_host = var.cloud_provider == "azure" ? module.environment.databricks_workspace_url : null
    storage_account = var.cloud_provider == "azure" ? module.environment.storage_account_name : null
  } : {
    databricks_host = var.cloud_provider == "oci" ? module.environment.databricks_url : null
    object_storage  = var.cloud_provider == "oci" ? module.environment.object_storage_namespace : null
    airflow_url     = var.cloud_provider == "oci" ? module.environment.airflow_url : null
  }
  sensitive = true
}

# Common outputs
output "cloud_provider" {
  description = "Cloud provider used for deployment"
  value       = var.cloud_provider
}

output "environment" {
  description = "Environment used for deployment"
  value       = var.environment
}

# OCI specific outputs
output "oci_compartment_id" {
  description = "OCI Compartment ID"
  value       = var.cloud_provider == "oci" ? module.environment.compartment_id : null
}

output "oci_vcn_id" {
  description = "OCI VCN ID"
  value       = var.cloud_provider == "oci" ? module.environment.vcn_id : null
}

output "oci_bucket_name" {
  description = "OCI Object Storage Bucket Name"
  value       = var.cloud_provider == "oci" ? module.environment.bucket_name : null
}

output "oci_databricks_url" {
  description = "OCI Databricks URL"
  value       = var.cloud_provider == "oci" ? module.environment.databricks_url : null
}

output "oci_airflow_url" {
  description = "OCI Airflow URL"
  value       = var.cloud_provider == "oci" ? module.environment.airflow_url : null
}

# Azure specific outputs
output "azure_resource_group_name" {
  description = "Azure Resource Group Name"
  value       = var.cloud_provider == "azure" ? module.environment.resource_group_name : null
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = var.cloud_provider == "azure" ? module.environment.vnet_id : null
}

output "azure_storage_account_name" {
  description = "Azure Storage Account Name"
  value       = var.cloud_provider == "azure" ? module.environment.storage_account_name : null
}

output "azure_databricks_workspace_url" {
  description = "Azure Databricks Workspace URL"
  value       = var.cloud_provider == "azure" ? module.environment.databricks_workspace_url : null
}

output "azure_data_factory_name" {
  description = "Azure Data Factory Name"
  value       = var.cloud_provider == "azure" ? module.environment.data_factory_name : null
}