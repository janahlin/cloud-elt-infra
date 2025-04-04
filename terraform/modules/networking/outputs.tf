output "vnet_id" {
  description = "The ID of the VNet"
  value       = var.cloud_provider == "azure" ? azurerm_virtual_network.vnet[0].id : null
}

output "vnet_name" {
  description = "The name of the VNet"
  value       = var.cloud_provider == "azure" ? azurerm_virtual_network.vnet[0].name : null
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = var.cloud_provider == "azure" ? azurerm_subnet.subnet[*].id : null
}

output "vcn_id" {
  description = "The ID of the VCN"
  value       = var.cloud_provider == "oci" ? oci_core_vcn.vcn[0].id : null
}

output "subnet_ocids" {
  description = "The OCIDs of the subnets"
  value       = var.cloud_provider == "oci" ? oci_core_subnet.subnet[*].id : null
}
