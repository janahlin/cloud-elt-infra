module "oci_networking" {
  source = "../../modules/networking"
}

module "oci_storage" {
  source = "../../modules/storage"
}

module "oci_compute" {
  source = "../../modules/compute"
}

module "oci_databricks" {
  source = "../../modules/databricks"
}

module "oci_elt_tool" {
  source = "../../modules/airflow"
}
