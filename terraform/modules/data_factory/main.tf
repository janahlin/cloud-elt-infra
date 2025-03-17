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

output "data_factory_name" {
  description = "Name of the Azure Data Factory"
  value       = var.cloud_provider == "azure" ? azurerm_data_factory.adf[0].name : null
}

output "data_factory_id" {
  description = "ID of the Azure Data Factory"
  value       = var.cloud_provider == "azure" ? azurerm_data_factory.adf[0].id : null
}

# Azure Data Factory resources
resource "azurerm_data_factory" "adf" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.resource_prefix}-${var.environment}-adf"
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

# Example pipeline
resource "azurerm_data_factory_pipeline" "example_pipeline" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "example-pipeline"
  data_factory_id     = azurerm_data_factory.adf[0].id
  
  activities_json = <<JSON
[
  {
    "name": "ExampleActivity",
    "type": "Copy",
    "inputs": [],
    "outputs": [],
    "typeProperties": {
      "source": {
        "type": "BinarySource",
        "storeSettings": {
          "type": "AzureBlobStorageReadSettings"
        }
      },
      "sink": {
        "type": "BinarySink",
        "storeSettings": {
          "type": "AzureBlobStorageWriteSettings"
        }
      }
    }
  }
]
JSON
}