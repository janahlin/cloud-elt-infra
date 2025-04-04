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
  description = "Subnet ID for Airflow deployment"
  type        = string
}

variable "image_id" {
  description = "Image ID for Airflow (OCI only)"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for OCI"
  type        = string
  default     = ""
}

variable "storage_bucket" {
  description = "Storage bucket name for Airflow logs"
  type        = string
  default     = ""
}

# Outputs
output "airflow_url" {
  description = "URL for Airflow UI"
  value       = var.cloud_provider == "oci" ? "http://${oci_core_instance.airflow[0].public_ip}:8080" : null
}

output "airflow_instance_id" {
  description = "ID of the Airflow instance"
  value       = var.cloud_provider == "oci" ? oci_core_instance.airflow[0].id : null
}

# OCI resources
resource "oci_core_instance" "airflow" {
  count               = var.cloud_provider == "oci" ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-${var.environment}-airflow"
  shape               = var.compute_shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.resource_prefix}-${var.environment}-airflow-vnic"
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
      "sudo apt-get install -y python3-pip docker.io docker-compose",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "mkdir -p ~/airflow",
      "cd ~/airflow",
      "echo 'AIRFLOW_UID=50000' > .env",
      "curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.5.1/docker-compose.yaml'",
      "mkdir -p ./dags ./logs ./plugins ./config",
      "echo -e 'AIRFLOW__CORE__LOAD_EXAMPLES: \"false\"' > ./config/airflow.cfg",
      "sudo docker-compose up -d"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "opc"
      private_key = file(var.ssh_private_key_path)
    }
  }
}
