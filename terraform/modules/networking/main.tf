variable "cloud_provider" {
  description = "Cloud provider (azure or oci)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC/VNet"
  type        = string
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
}

# OCI specific variables
variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
  default     = ""
}

# Azure specific variables
variable "location" {
  description = "Azure region"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

# Outputs for OCI
output "vcn_id" {
  description = "ID of the created VCN (OCI)"
  value       = var.cloud_provider == "oci" ? oci_core_vcn.vcn[0].id : null
}

output "subnet_ocids" {
  description = "List of subnet OCIDs (OCI)"
  value       = var.cloud_provider == "oci" ? oci_core_subnet.subnet.*.id : null
}

# Outputs for Azure
output "vnet_id" {
  description = "ID of the created VNet (Azure)"
  value       = var.cloud_provider == "azure" ? azurerm_virtual_network.vnet[0].id : null
}

output "subnet_ids" {
  description = "List of subnet IDs (Azure)"
  value       = var.cloud_provider == "azure" ? azurerm_subnet.subnet.*.id : null
}

# OCI Resources
resource "oci_core_vcn" "vcn" {
  count          = var.cloud_provider == "oci" ? 1 : 0
  cidr_block     = var.vpc_cidr
  compartment_id = var.compartment_id
  display_name   = "${var.resource_prefix}-${var.environment}-vcn"
}

resource "oci_core_internet_gateway" "ig" {
  count          = var.cloud_provider == "oci" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "${var.resource_prefix}-${var.environment}-ig"
}

resource "oci_core_route_table" "route_table" {
  count          = var.cloud_provider == "oci" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "${var.resource_prefix}-${var.environment}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.ig[0].id
  }
}

resource "oci_core_subnet" "subnet" {
  count             = var.cloud_provider == "oci" ? var.subnet_count : 0
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn[0].id
  display_name      = "${var.resource_prefix}-${var.environment}-subnet-${count.index}"
  route_table_id    = oci_core_route_table.route_table[0].id
  security_list_ids = [oci_core_vcn.vcn[0].default_security_list_id]
}

# Azure Resources
resource "azurerm_virtual_network" "vnet" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-vnet"
  address_space       = [var.vpc_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  count                = var.cloud_provider == "azure" ? var.subnet_count : 0
  name                 = "${var.resource_prefix}-${var.environment}-subnet-${count.index}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [cidrsubnet(var.vpc_cidr, 8, count.index)]
}