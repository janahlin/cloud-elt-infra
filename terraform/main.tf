provider "azurerm" {
  features {}
}

provider "oci" {
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  fingerprint  = var.oci_fingerprint
  private_key  = file(var.oci_private_key_path)
  region       = var.oci_region
}

module "networking" {
  source = "./modules/networking"
}

module "storage" {
  source = "./modules/storage"
}

module "compute" {
  source = "./modules/compute"
}

module "databricks" {
  source = "./modules/databricks"
}

module "elt_tool" {
  source = var.cloud_provider == "azure" ? "./modules/data_factory" : "./modules/airflow"
}

module "environment" {
  source = "./environments/${var.cloud_provider}"
}
