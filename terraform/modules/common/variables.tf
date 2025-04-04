variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix to be used for resource names"
  type        = string
  default     = "cloud-elt"
}
