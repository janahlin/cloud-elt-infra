output "compartment_id" {
  description = "OCI Compartment ID"
  value       = oci_identity_compartment.compartment.id
}

output "compartment_name" {
  description = "OCI Compartment Name"
  value       = oci_identity_compartment.compartment.name
}

output "vcn_id" {
  description = "OCI VCN ID"
  value       = module.networking.vcn_id
}

output "subnet_ocids" {
  description = "OCI Subnet OCIDs"
  value       = module.networking.subnet_ocids
}

output "object_storage_namespace" {
  description = "OCI Object Storage Namespace"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_name" {
  description = "OCI Storage Bucket Name"
  value       = module.storage.bucket_name
}

output "databricks_url" {
  description = "URL for Databricks workspace"
  value       = module.databricks.databricks_url
}

output "airflow_url" {
  description = "URL for Airflow UI"
  value       = module.airflow.airflow_url
}
