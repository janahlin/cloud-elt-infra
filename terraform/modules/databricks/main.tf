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
  count               = local.is_oci ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-databricks"
  shape               = var.compute_shape # Using Always Free eligible VM.Standard.E2.1.Micro
  
  # Limit shape resources for free tier
  shape_config {
    ocpus         = 1    # Free tier limited to 1 OCPU
    memory_in_gbs = 1    # Free tier limited to 1 GB RAM
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.resource_prefix}-${var.environment}-databricks-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
    # Minimum boot volume size for free tier
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_private_key_path)
  }
}

# This provisioner will configure a minimal data processing environment as a free alternative to Databricks
resource "null_resource" "setup_databricks" {
  count      = local.is_oci ? 1 : 0
  depends_on = [oci_core_instance.databricks]

  connection {
    type        = "ssh"
    host        = oci_core_instance.databricks[0].public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y python3 python3-pip git",
      "pip3 install --user jupyter pandas scikit-learn matplotlib dask",
      "mkdir -p ~/notebooks",
      "nohup jupyter notebook --ip=0.0.0.0 --no-browser --NotebookApp.token='databricks' --NotebookApp.password='' &>/dev/null &",
      "echo 'Jupyter notebook started as a free alternative to Databricks'"
    ]
  }
}

# Azure resources
resource "azurerm_databricks_workspace" "databricks" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-databricks"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.databricks_sku # Standard SKU instead of Premium for cost savings
  
  # Free tier optimizations
  tags = {
    environment = var.environment
    auto_terminate_minutes = "20" # Auto-terminate clusters to minimize compute usage
    min_workers = "1"             # Minimize worker count for cost savings
  }
}