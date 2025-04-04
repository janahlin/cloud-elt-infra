#!/bin/bash
set -e

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

# Set Ansible config path
export ANSIBLE_CONFIG="$(pwd)/ansible/ansible.cfg"

# Get absolute paths
CURRENT_DIR="$(pwd)"
TEMPLATE_FILE="$CURRENT_DIR/scripts/terraform.tfvars.j2"

# Create a temporary directory for our work
TEMP_DIR=$(mktemp -d)
PLAYBOOK_FILE="$TEMP_DIR/playbook.yml"

# Create the Jinja2 template for terraform.tfvars
mkdir -p scripts
cat > "$TEMPLATE_FILE" << 'EOF'
# Common variables
cloud_provider = "{{ cloud_provider }}"
environment = "{{ env_name }}"
resource_prefix = "{{ resource_prefix }}"
vpc_cidr = "{{ vpc_cidr }}"
subnet_count = {{ subnet_count }}

# Test variables
test_resource_name = "{{ test_resource_name | default('') }}"
test_complex_name = "{{ test_complex_name | default('') }}"
test_number = {{ test_number | default(0) }}

# Azure specific variables
azure_subscription_id = "{{ vault_azure_subscription_id | default('') }}"
azure_client_id = "{{ vault_azure_client_id | default('') }}"
azure_client_secret = "{{ vault_azure_client_secret | default('') }}"
azure_tenant_id = "{{ vault_azure_tenant_id | default('') }}"
azure_location = "{{ azure_location }}"
azure_resource_group_name = "{{ azure_resource_group_name }}"
azure_storage_account_name = "{{ azure_storage_account_name }}"
azure_virtual_network_name = "{{ azure_virtual_network_name }}"
azure_subnet_name = "{{ azure_subnet_name }}"
azure_vm_name = "{{ azure_vm_name }}"
azure_vm_size = "{{ vm_size }}"
azure_vm_os_disk_size_gb = {{ azure_vm_os_disk_size_gb }}
azure_vm_admin_username = "{{ azure_vm_admin_username }}"
storage_tier = "{{ storage_tier }}"
databricks_sku = "{{ databricks_sku }}"

# Azure storage configuration
azure_storage_account_tier = "{{ azure_storage_account_tier }}"
azure_storage_min_tls_version = "{{ azure_storage_min_tls_version }}"
azure_storage_container_access_type = "{{ azure_storage_container_access_type }}"

# OCI specific variables
oci_tenancy_ocid = "{{ vault_oci_tenancy_ocid | default('') }}"
oci_user_ocid = "{{ vault_oci_user_ocid | default('') }}"
oci_fingerprint = "{{ vault_oci_fingerprint | default('') }}"
oci_private_key_path = "{{ oci_private_key_path }}"
oci_region = "{{ oci_region }}"
oci_compartment_id = "{{ oci_compartment_id }}"
oci_vcn_name = "{{ oci_vcn_name }}"
oci_subnet_name = "{{ oci_subnet_name }}"
oci_instance_name = "{{ oci_instance_name }}"
compute_shape = "{{ compute_shape }}"
oci_instance_ocpus = {{ oci_instance_ocpus }}
oci_instance_memory_in_gbs = {{ oci_instance_memory_in_gbs }}
oci_instance_os = "{{ oci_instance_os }}"
oci_instance_os_version = "{{ oci_instance_os_version }}"
ssh_public_key = "{{ lookup('file', ssh_public_key_path) }}"
ssh_private_key_path = "{{ ssh_private_key_path }}"

# OCI storage configuration
oci_storage_tier = "{{ oci_storage_tier }}"
oci_storage_versioning = "{{ oci_storage_versioning }}"
oci_storage_auto_tiering = "{{ oci_storage_auto_tiering }}"
oci_storage_lifecycle_days = {{ oci_storage_lifecycle_days }}

# OCI compute configuration
oci_compute_ocpus = {{ oci_compute_ocpus }}
oci_compute_memory_gb = {{ oci_compute_memory_gb }}

# Databricks configuration
databricks_docker_port = {{ databricks_docker_port }}
databricks_docker_image = "{{ databricks_docker_image }}"

# Monitoring configuration
log_retention_days = {{ log_retention_days }}
alert_email_addresses = "{{ alert_email_addresses }}"
EOF

# Generate a fix for Ansible vars
cat > "$TEMP_DIR/vars_override.yml" << EOF
# Fix for environment variable
environment: "$ENV"
EOF

# Let's extract all var values we need to rebuild complex variables
cat > "$TEMP_DIR/rebuild_vars.yml" << EOF
---
- hosts: localhost
  connection: local
  gather_facts: false
  vars_files:
    - $CURRENT_DIR/ansible/group_vars/all/vars.yml
    - $CURRENT_DIR/ansible/group_vars/$ENV/vars.yml
  vars:
    environment: "$ENV"
  tasks:
    - name: Collect all variables that use environment
      set_fact:
        resource_prefix: "{{ resource_prefix }}"
        env_name: "$ENV"
        cloud_provider: "{{ cloud_provider }}"

    - name: Rebuild complex variables
      set_fact:
        azure_resource_group_name: "{{ resource_prefix }}-{{ env_name }}-rg"
        azure_storage_account_name: "{{ resource_prefix }}{{ env_name }}sa"
        azure_virtual_network_name: "{{ resource_prefix }}-{{ env_name }}-vnet"
        azure_subnet_name: "{{ resource_prefix }}-{{ env_name }}-subnet"
        azure_vm_name: "{{ resource_prefix }}-{{ env_name }}-vm"
        test_resource_name: "{{ resource_prefix }}-{{ env_name }}-test"
        test_complex_name: "{{ resource_prefix }}-{{ env_name }}-{{ cloud_provider }}-test"
        oci_vcn_name: "{{ resource_prefix }}-{{ env_name }}-vcn"
        oci_subnet_name: "{{ resource_prefix }}-{{ env_name }}-subnet"
        oci_instance_name: "{{ resource_prefix }}-{{ env_name }}-instance"

    - name: Export rebuilt variables to file
      copy:
        content: "{{ vars | to_nice_yaml }}"
        dest: "$TEMP_DIR/rebuilt_vars.yml"
EOF

# Run the rebuild vars playbook first
ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_PASS_FILE" ansible-playbook "$TEMP_DIR/rebuild_vars.yml" -e "environment=$ENV" -e @"$CURRENT_DIR/ansible/group_vars/$ENV/vault.yml" > /dev/null 2>&1

# Create a simpler Ansible playbook that uses templates directly
cat > "$PLAYBOOK_FILE" << EOF
---
- hosts: localhost
  connection: local
  gather_facts: false
  vars_files:
    - $CURRENT_DIR/ansible/group_vars/all/vars.yml
    - $CURRENT_DIR/ansible/group_vars/$ENV/vars.yml
    - $TEMP_DIR/vars_override.yml
    - $TEMP_DIR/rebuilt_vars.yml
  pre_tasks:
    - name: Set environment name explicitly to override Ansible's reserved name
      set_fact:
        env_name: "$ENV"

    - name: Debug environment values
      debug:
        msg:
          - "Environment: {{ environment }}"
          - "env_name: {{ env_name }}"
          - "Azure RG: {{ azure_resource_group_name }}"
  tasks:
    - name: Create terraform.tfvars
      template:
        src: $TEMPLATE_FILE
        dest: $CURRENT_DIR/terraform/terraform.tfvars
EOF

# Run the playbook to generate terraform.tfvars
echo "Generating terraform.tfvars using Ansible..."
ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_PASS_FILE" ansible-playbook "$PLAYBOOK_FILE" -e "environment=$ENV" -e @"$CURRENT_DIR/ansible/group_vars/$ENV/vault.yml"

# Clean up
rm -rf "$TEMP_DIR"

echo "Successfully generated terraform.tfvars for $ENV environment"
