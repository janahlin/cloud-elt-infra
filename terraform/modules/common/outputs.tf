output "common_tags" {
  description = "Common tags to be used across all resources"
  value       = local.common_tags
}

output "resource_prefix" {
  description = "Resource prefix to be used across all resources"
  value       = var.resource_prefix
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "location" {
  description = "Region/location for resources"
  value       = var.location
}

output "cloud_provider" {
  description = "Cloud provider being used"
  value       = var.cloud_provider
}
