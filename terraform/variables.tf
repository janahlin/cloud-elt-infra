variable "cloud_provider" {
  description = "Choose the cloud provider (oci or azure)"
  type        = string
}

variable "use_airflow" {
  description = "Choose whether to use Apache Airflow (true) or Azure Data Factory (false)"
  type        = bool
}

variable "environment" {
  description = "Choose the deployment environment (dev, staging, production)"
  type        = string
}