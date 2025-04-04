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
  description = "Databricks workspace SKU"
  type        = string
  default     = "premium"
}

# OCI specific variables
variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = ""
}

variable "availability_domain" {
  description = "OCI availability domain"
  type        = string
  default     = ""
}

variable "compute_shape" {
  description = "OCI compute shape"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "subnet_id" {
  description = "OCI subnet ID for Databricks host"
  type        = string
  default     = ""
}

variable "image_id" {
  description = "OCI image ID for Databricks host"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for OCI instance"
  type        = string
  default     = ""
}

variable "databricks_docker_port" {
  description = "Port for Databricks Docker container"
  type        = number
  default     = 8443
}

variable "databricks_docker_image" {
  description = "Docker image for Databricks"
  type        = string
  default     = "databricks/community-edition"
}

variable "oci_compute_ocpus" {
  description = "Number of OCPUs for OCI databricks instance"
  type        = number
  default     = 1
}

variable "oci_compute_memory_gb" {
  description = "Memory in GB for OCI databricks instance"
  type        = number
  default     = 1
}
