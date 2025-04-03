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

# OCI specific variables
variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
  default     = ""
}

variable "availability_domain" {
  description = "OCI Availability Domain"
  type        = string
  default     = ""
}

variable "compute_shape" {
  description = "OCI Compute shape"
  type        = string
  default     = "VM.Standard2.1"
}

variable "image_id" {
  description = "Image ID for compute instance (OCI only)"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key content for OCI"
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

variable "subnet_id" {
  description = "Subnet ID for compute deployment"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

# Define locals for provider checks
locals {
  is_azure = var.cloud_provider == "azure"
  is_oci   = var.cloud_provider == "oci"
}

# Outputs
output "instance_ip" {
  description = "IP address of the compute instance"
  value       = var.cloud_provider == "oci" ? oci_core_instance.compute[0].public_ip : (
    var.cloud_provider == "azure" ? azurerm_public_ip.public_ip[0].ip_address : null
  )
}

output "instance_id" {
  description = "ID of the compute instance"
  value       = var.cloud_provider == "oci" ? oci_core_instance.compute[0].id : (
    var.cloud_provider == "azure" ? azurerm_linux_virtual_machine.vm[0].id : null
  )
}

# OCI resources
resource "oci_core_instance" "compute" {
  count               = local.is_oci ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-vm"
  shape               = var.compute_shape # VM.Standard.E2.1.Micro for Always Free Tier

  shape_config {
    ocpus         = 1    # Free tier limited to 1 OCPU
    memory_in_gbs = 1    # Free tier limited to 1 GB RAM
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.resource_prefix}-${var.environment}-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
    # Use minimal boot volume size for free tier
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Azure resources
resource "azurerm_public_ip" "public_ip" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[0].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-vm"
  computer_name       = "${var.resource_prefix}-${var.environment}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic[0].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  boot_diagnostics {
    storage_account_uri = null
  }

  tags = {
    environment = var.environment
  }
}

# Free tier eligible boot volume backup policy - no regular backups
resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup_policy" {
  count     = local.is_oci ? 1 : 0
  asset_id  = data.oci_core_boot_volume_attachments.boot_volume_attachments[0].boot_volume_attachments[0].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.boot_volume_backup_policies[0].volume_backup_policies[0].id
}

data "oci_core_boot_volume_attachments" "boot_volume_attachments" {
  count          = local.is_oci ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.compute[0].id
}

data "oci_core_volume_backup_policies" "boot_volume_backup_policies" {
  count          = local.is_oci ? 1 : 0
  filter {
    name   = "display_name"
    values = ["silver"]
  }
}