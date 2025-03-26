output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace (Azure)"
  value       = var.cloud_provider == "azure" ? one(azurerm_log_analytics_workspace.law[*].id) : null
}

output "log_analytics_workspace_primary_key" {
  description = "The primary key of the Log Analytics Workspace (Azure)"
  value       = var.cloud_provider == "azure" ? one(azurerm_log_analytics_workspace.law[*].primary_shared_key) : null
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of Application Insights (Azure)"
  value       = var.cloud_provider == "azure" ? one(azurerm_application_insights.appinsights[*].instrumentation_key) : null
  sensitive   = true
}

output "action_group_id" {
  description = "The ID of the Azure Monitor Action Group"
  value       = var.cloud_provider == "azure" ? one(azurerm_monitor_action_group.main[*].id) : null
}

output "oci_log_group_id" {
  description = "OCID of the OCI Logging Group"
  value       = var.cloud_provider == "oci" ? one(oci_logging_log_group.log_group[*].id) : null
}

output "oci_notification_topic_id" {
  description = "OCID of the OCI Notification Topic"
  value       = var.cloud_provider == "oci" && length(var.notification_topic_ids) == 0 ? one(oci_ons_notification_topic.alert_topic[*].id) : null
} 