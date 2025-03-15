module "azure_networking" {
  source = "../../modules/networking"
}

module "azure_storage" {
  source = "../../modules/storage"
}

module "azure_compute" {
  source = "../../modules/compute"
}

module "azure_databricks" {
  source = "../../modules/databricks"
}

module "azure_elt_tool" {
  source = "../../modules/data_factory"
}
