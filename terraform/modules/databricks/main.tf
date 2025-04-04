# Define locals for provider checks
locals {
  is_azure = var.cloud_provider == "azure"
  is_oci   = var.cloud_provider == "oci"
}

# OCI resources
resource "oci_core_instance" "databricks" {
  count               = local.is_oci ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-databricks"
  shape               = var.compute_shape

  # Compute resources
  shape_config {
    ocpus         = var.oci_compute_ocpus
    memory_in_gbs = var.oci_compute_memory_gb
  }

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
    ssh_authorized_keys = file(var.ssh_private_key_path)
  }
}

# Setup Databricks on OCI instance
resource "null_resource" "setup_databricks" {
  count = local.is_oci ? 1 : 0

  triggers = {
    instance_id = oci_core_instance.databricks[0].id
  }

  connection {
    type        = "ssh"
    host        = oci_core_instance.databricks[0].public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker run -d -p ${var.databricks_docker_port}:${var.databricks_docker_port} --name databricks ${var.databricks_docker_image}"
    ]
  }
}

# Azure resources
resource "azurerm_databricks_workspace" "databricks" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-databricks"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.databricks_sku
}
