#!/bin/bash

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi

ENV=$1
VAULT_PASS_FILE=".vault_pass_${ENV}.txt"

# Check if vault password file exists
if [ ! -f "$VAULT_PASS_FILE" ]; then
    echo "Error: Vault password file $VAULT_PASS_FILE not found"
    echo "Please run setup-ansible-vault.sh first"
    exit 1
fi

# Function to get value from vault file
get_vault_value() {
    local key=$1
    ANSIBLE_VAULT_IDENTITY_LIST="${ENV}@${VAULT_PASS_FILE}" ansible-vault view --vault-id "${ENV}@${VAULT_PASS_FILE}" "ansible/group_vars/$ENV/vault.yml" 2>/dev/null | grep "^$key:" | awk '{print $2}' | tr -d '"'
}

# Function to get value from vars file
get_vars_value() {
    local key=$1
    cat "ansible/group_vars/all/vars.yml" | grep "^$key:" | awk '{print $2}' | tr -d '"'
}

# Function to read SSH public key content
get_ssh_public_key() {
    local key_path=$(get_vars_value ssh_public_key_path)
    if [ -f "$key_path" ]; then
        cat "$key_path"
    else
        echo "Error: SSH public key file not found at $key_path"
        exit 1
    fi
}

# Generate terraform.tfvars
cat > "terraform/terraform.tfvars" << EOF
# Common variables
cloud_provider = "$(get_vars_value cloud_provider)"
environment = "$(get_vars_value environment)"
resource_prefix = "$(get_vars_value resource_prefix)"
vpc_cidr = "$(get_vars_value vpc_cidr)"
subnet_count = $(get_vars_value subnet_count)

# Azure specific variables
azure_subscription_id = "$(get_vault_value vault_azure_subscription_id)"
azure_client_id = "$(get_vault_value vault_azure_client_id)"
azure_client_secret = "$(get_vault_value vault_azure_client_secret)"
azure_tenant_id = "$(get_vault_value vault_azure_tenant_id)"
azure_location = "$(get_vars_value azure_location)"
azure_resource_group_name = "$(get_vars_value azure_resource_group_name)"
azure_storage_account_name = "$(get_vars_value azure_storage_account_name)"
azure_virtual_network_name = "$(get_vars_value azure_virtual_network_name)"
azure_subnet_name = "$(get_vars_value azure_subnet_name)"
azure_vm_name = "$(get_vars_value azure_vm_name)"
azure_vm_size = "$(get_vars_value vm_size)"
azure_vm_os_disk_size_gb = $(get_vars_value azure_vm_os_disk_size_gb)
azure_vm_admin_username = "$(get_vars_value azure_vm_admin_username)"
storage_tier = "$(get_vars_value storage_tier)"
databricks_sku = "$(get_vars_value databricks_sku)"

# Azure storage configuration
azure_storage_account_tier = "$(get_vars_value azure_storage_account_tier)"
azure_storage_min_tls_version = "$(get_vars_value azure_storage_min_tls_version)"
azure_storage_container_access_type = "$(get_vars_value azure_storage_container_access_type)"

# OCI specific variables
oci_tenancy_ocid = "$(get_vault_value vault_oci_tenancy_ocid)"
oci_user_ocid = "$(get_vault_value vault_oci_user_ocid)"
oci_fingerprint = "$(get_vault_value vault_oci_fingerprint)"
oci_private_key_path = "$(get_vars_value oci_private_key_path)"
oci_region = "$(get_vars_value oci_region)"
oci_compartment_id = "$(get_vars_value oci_compartment_id)"
oci_vcn_name = "$(get_vars_value oci_vcn_name)"
oci_subnet_name = "$(get_vars_value oci_subnet_name)"
oci_instance_name = "$(get_vars_value oci_instance_name)"
compute_shape = "$(get_vars_value compute_shape)"
oci_instance_ocpus = $(get_vars_value oci_instance_ocpus)
oci_instance_memory_in_gbs = $(get_vars_value oci_instance_memory_in_gbs)
oci_instance_os = "$(get_vars_value oci_instance_os)"
oci_instance_os_version = "$(get_vars_value oci_instance_os_version)"
ssh_public_key = "$(get_ssh_public_key)"
ssh_private_key_path = "$(get_vars_value ssh_private_key_path)"

# OCI storage configuration
oci_storage_tier = "$(get_vars_value oci_storage_tier)"
oci_storage_versioning = "$(get_vars_value oci_storage_versioning)"
oci_storage_auto_tiering = "$(get_vars_value oci_storage_auto_tiering)"
oci_storage_lifecycle_days = $(get_vars_value oci_storage_lifecycle_days)

# OCI compute configuration
oci_compute_ocpus = $(get_vars_value oci_compute_ocpus)
oci_compute_memory_gb = $(get_vars_value oci_compute_memory_gb)

# Databricks configuration
databricks_docker_port = $(get_vars_value databricks_docker_port)
databricks_docker_image = "$(get_vars_value databricks_docker_image)"

# Monitoring configuration
log_retention_days = $(get_vars_value log_retention_days)
alert_email_addresses = "$(get_vars_value alert_email_addresses)"
EOF

echo "Generated terraform.tfvars from Ansible variables and vault" 