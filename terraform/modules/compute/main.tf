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

# Outputs
output "instance_ip" {
  description = "IP address of the compute instance"
  value       = var.cloud_provider == "oci" ? oci_core_instance.compute[0].public_ip : (
    var.cloud_provider == "azure" ? azurerm_public_ip.pip[0].ip_address : null
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
  count               = var.cloud_provider == "oci" ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-compute"
  shape               = var.compute_shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.resource_prefix}-${var.environment}-compute-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Azure resources
resource "azurerm_public_ip" "pip" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[0].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
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
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}