locals {
  is_azure = var.cloud_provider == "azure"
  is_oci   = var.cloud_provider == "oci"
}

############################################################
# Azure Resources
############################################################

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "law" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
}

# Application Insights for application monitoring
resource "azurerm_application_insights" "appinsights" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law[0].id
}

# Azure Monitor Action Group for alerting
resource "azurerm_monitor_action_group" "main" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-actiongroup"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# Azure metric alerts for critical services
resource "azurerm_monitor_metric_alert" "high_cpu" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-highcpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.compute_resource_id]
  description         = "Alert when CPU exceeds 80%"
  
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }
}

############################################################
# OCI Resources
############################################################

# OCI Logging Group for centralized logging
resource "oci_logging_log_group" "log_group" {
  count          = local.is_oci ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.resource_prefix}-${var.environment}-loggroup"
  description    = "Log group for ELT infrastructure"
}

# OCI Monitoring Alarm for high CPU
resource "oci_monitoring_alarm" "high_cpu_alarm" {
  count          = local.is_oci ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.resource_prefix}-${var.environment}-highcpu-alarm"
  is_enabled     = true
  
  metric_compartment_id = var.compartment_id
  namespace             = "oci_computeagent"
  resource_group        = "${var.resource_prefix}-${var.environment}"
  query                 = "CpuUtilization[1m].mean() > 80"
  severity              = "CRITICAL"
  
  message_format = "ONS_OPTIMIZED"
  
  destinations = var.notification_topic_ids
  
  body = "High CPU utilization detected on compute instance"
}

# OCI Notifications Topic for alerting
resource "oci_ons_notification_topic" "alert_topic" {
  count          = local.is_oci && length(var.notification_topic_ids) == 0 ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.resource_prefix}-${var.environment}-alerts"
  description    = "Notification topic for infrastructure alerts"
}

# OCI Notifications Subscription for email
resource "oci_ons_subscription" "email_subscription" {
  count               = local.is_oci && length(var.notification_topic_ids) == 0 ? length(var.alert_email_addresses) : 0
  compartment_id      = var.compartment_id
  topic_id            = oci_ons_notification_topic.alert_topic[0].id
  endpoint            = var.alert_email_addresses[count.index]
  protocol            = "EMAIL"
} 