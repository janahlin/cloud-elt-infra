resource "oci_identity_compartment" "compartment" {
  name          = "${var.resource_prefix}-${var.environment}-compartment"
  description   = "Compartment for ${var.environment} environment"
  compartment_id = var.oci_tenancy_ocid
}

# Get the availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_tenancy_ocid
}

# Get the object storage namespace
data "oci_objectstorage_namespace" "ns" {
  compartment_id = oci_identity_compartment.compartment.id
}

module "networking" {
  source         = "../../modules/networking"
  cloud_provider = "oci"
  environment    = var.environment
  resource_prefix = var.resource_prefix
  compartment_id = oci_identity_compartment.compartment.id
  vpc_cidr       = var.vpc_cidr
  subnet_count   = var.subnet_count
}

module "storage" {
  source                 = "../../modules/storage"
  cloud_provider         = "oci"
  environment            = var.environment
  resource_prefix        = var.resource_prefix
  compartment_id         = oci_identity_compartment.compartment.id
  object_storage_namespace = data.oci_objectstorage_namespace.ns.namespace
}

# Find a suitable image
data "oci_core_images" "oracle_linux" {
  compartment_id           = oci_identity_compartment.compartment.id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.compute_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

module "databricks" {
  source              = "../../modules/databricks"
  cloud_provider      = "oci"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  compartment_id      = oci_identity_compartment.compartment.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compute_shape       = var.compute_shape
  subnet_id           = module.networking.subnet_ocids[0]
  image_id            = data.oci_core_images.oracle_linux.images[0].id
  ssh_private_key_path = var.ssh_private_key_path
}

module "airflow" {
  source              = "../../modules/airflow"
  cloud_provider      = "oci"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  compartment_id      = oci_identity_compartment.compartment.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compute_shape       = var.compute_shape
  subnet_id           = module.networking.subnet_ocids[1]
  image_id            = data.oci_core_images.oracle_linux.images[0].id
  ssh_private_key_path = var.ssh_private_key_path
  storage_bucket      = module.storage.bucket_name
}

module "compute" {
  source              = "../../modules/compute"
  cloud_provider      = "oci"
  environment         = var.environment
  resource_prefix     = var.resource_prefix
  compartment_id      = oci_identity_compartment.compartment.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compute_shape       = var.compute_shape
  subnet_id           = module.networking.subnet_ocids[2]
  image_id            = data.oci_core_images.oracle_linux.images[0].id
  ssh_public_key      = var.ssh_public_key
}