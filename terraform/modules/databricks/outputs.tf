output "databricks_workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = var.cloud_provider == "azure" ? azurerm_databricks_workspace.databricks[0].id : null
}

output "databricks_workspace_url" {
  description = "The URL of the Databricks workspace"
  value       = var.cloud_provider == "azure" ? azurerm_databricks_workspace.databricks[0].workspace_url : null
}

output "databricks_host_id" {
  description = "The ID of the Databricks host VM in OCI"
  value       = var.cloud_provider == "oci" ? oci_core_instance.databricks[0].id : null
}

output "databricks_host_ip" {
  description = "The public IP of the Databricks host in OCI"
  value       = var.cloud_provider == "oci" ? oci_core_instance.databricks[0].public_ip : null
}

output "databricks_url" {
  description = "The URL to access Databricks in OCI (placeholder)"
  value       = var.cloud_provider == "oci" ? "https://${oci_core_instance.databricks[0].public_ip}" : null
}