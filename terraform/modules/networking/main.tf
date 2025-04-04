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
  count          = var.cloud_provider == "oci" ? var.subnet_count : 0
  cidr_block     = cidrsubnet(var.vpc_cidr, 8, count.index)
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "${var.resource_prefix}-${var.environment}-subnet-${count.index}"
  route_table_id = oci_core_route_table.route_table[0].id
}

# Azure Resources
resource "azurerm_virtual_network" "vnet" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vpc_cidr]
}

resource "azurerm_subnet" "subnet" {
  count                = var.cloud_provider == "azure" ? var.subnet_count : 0
  name                 = "${var.resource_prefix}-${var.environment}-subnet-${count.index}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [cidrsubnet(var.vpc_cidr, 8, count.index)]
}
