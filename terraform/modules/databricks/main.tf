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
  default     = "VM.Standard2.4"
}

variable "subnet_id" {
  description = "Subnet ID for Databricks deployment"
  type        = string
}

variable "image_id" {
  description = "Image ID for Databricks (OCI only)"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for OCI"
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

variable "databricks_sku" {
  description = "Databricks SKU (standard, premium, trial)"
  type        = string
  default     = "premium"
}

# Outputs
output "databricks_url" {
  description = "URL for Databricks workspace (OCI)"
  value       = var.cloud_provider == "oci" ? "https://${oci_core_instance.databricks[0].public_ip}:8443" : null
}

output "databricks_workspace_url" {
  description = "URL for Databricks workspace (Azure)"
  value       = var.cloud_provider == "azure" ? azurerm_databricks_workspace.databricks[0].workspace_url : null
}

# OCI resources
resource "oci_core_instance" "databricks" {
  count               = var.cloud_provider == "oci" ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-databricks"
  shape               = var.compute_shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.resource_prefix}-${var.environment}-databricks-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo docker pull databricksruntime/standard:latest",
      "sudo docker run -d -p 8443:8443 --name databricks-runtime databricksruntime/standard:latest"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "opc"
      private_key = file(var.ssh_private_key_path)
    }
  }
}

# Azure resources
resource "azurerm_databricks_workspace" "databricks" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-databricks"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.databricks_sku

  custom_parameters {
    no_public_ip        = false
    virtual_network_id  = var.subnet_id
  }

  tags = {
    Environment = var.environment
  }
}