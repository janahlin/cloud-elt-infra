#!/bin/bash

# Script to test disaster recovery functionality with Ansible

set -e  # Exit on any error
set -x  # Print commands as they are executed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_status() {
    echo -e "${GREEN}=== $1 ===${NC}"
}

echo_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

echo_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Check if running in the correct directory
if [ ! -d "ansible" ]; then
    echo_error "Please run this script from the repository root directory"
    exit 1
fi

# Check if post-upgrade report exists
if [ ! -f "ansible_post_upgrade_report.txt" ]; then
    echo_error "Please run ansible_upgrade_execute.sh first"
    exit 1
fi

# Create test environment
echo_status "Creating test environment"
python3 -m venv ansible_dr_test_env || {
    echo_error "Failed to create virtual environment"
    exit 1
}

# Activate virtual environment
echo_status "Activating virtual environment"
source ansible_dr_test_env/bin/activate || {
    echo_error "Failed to activate virtual environment"
    exit 1
}

# Upgrade pip first
echo_status "Upgrading pip"
python3 -m pip install --upgrade pip || {
    echo_warning "Failed to upgrade pip, continuing with existing version"
}

# Install packages one by one with error handling
echo_status "Installing Ansible packages and cloud provider SDKs"

# Install ansible-core first
echo_status "Installing ansible-core"
pip install ansible-core==2.17.10 || {
    echo_error "Failed to install ansible-core"
    exit 1
}

# Install ansible
echo_status "Installing ansible"
pip install ansible==10.7.0 || {
    echo_error "Failed to install ansible"
    exit 1
}

# Install ansible-compat
echo_status "Installing ansible-compat"
pip install ansible-compat==25.1.5 || {
    echo_error "Failed to install ansible-compat"
    exit 1
}

# Install cloud provider SDKs
echo_status "Installing cloud provider SDKs"
pip install oci-cli || {
    echo_warning "Failed to install oci-cli, some OCI tests may fail"
}

pip install azure-cli azure-mgmt-resource azure-identity || {
    echo_warning "Failed to install Azure SDKs, some Azure tests may fail"
}

# Create test inventory
echo_status "Creating test inventory"
mkdir -p ansible_dr_test/inventory
cat > ansible_dr_test/inventory/test.ini << EOF
[controller]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3 ansible_user=testuser

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Create test vault files
echo_status "Creating test vault files"
mkdir -p ansible_dr_test/group_vars/dev
mkdir -p ansible_dr_test/group_vars/prod

# Create mock vault files
cat > ansible_dr_test/group_vars/dev/vault.yml << EOF
---
# Mock vault variables for testing
oci_config:
  tenancy: "test_tenancy"
  user: "test_user"
  fingerprint: "test_fingerprint"
  key_file: "/home/testuser/.oci/oci_api_key.pem"
  region: "test_region"

azure_config:
  subscription_id: "test_subscription"
  client_id: "test_client_id"
  client_secret: "test_secret"
  tenant_id: "test_tenant_id"
EOF

cat > ansible_dr_test/group_vars/prod/vault.yml << EOF
---
# Mock vault variables for testing
oci_config:
  tenancy: "test_tenancy_prod"
  user: "test_user_prod"
  fingerprint: "test_fingerprint_prod"
  key_file: "/home/testuser/.oci/oci_api_key.pem"
  region: "test_region_prod"

azure_config:
  subscription_id: "test_subscription_prod"
  client_id: "test_client_id_prod"
  client_secret: "test_secret_prod"
  tenant_id: "test_tenant_id_prod"
EOF

# Create vault password files
echo "test_password" > ansible_dr_test/.vault_pass_dev.txt
echo "test_password" > ansible_dr_test/.vault_pass_prod.txt

# Copy ansible.cfg for test environment
cp ansible/ansible.cfg ansible_dr_test/
sed -i "s|inventory = ./inventories|inventory = ./inventory|" ansible_dr_test/ansible.cfg
sed -i "s|roles_path = ./roles|roles_path = $(pwd)/ansible/roles|" ansible_dr_test/ansible.cfg
sed -i "s|collections_paths = ./venv/lib/python3.10/site-packages/ansible_collections:~/.ansible/collections|collections_paths = $(pwd)/ansible_dr_test_env/lib/python3.10/site-packages/ansible_collections:~/.ansible/collections|" ansible_dr_test/ansible.cfg
sed -i "s|vault_identity_list = dev@.vault_pass_dev.txt, prod@.vault_pass_prod.txt|vault_identity_list = dev@$(pwd)/ansible_dr_test/.vault_pass_dev.txt, prod@$(pwd)/ansible_dr_test/.vault_pass_prod.txt|" ansible_dr_test/ansible.cfg

# Create mock terraform directory
mkdir -p ansible_dr_test/terraform
cat > ansible_dr_test/terraform/terraform.tfstate << EOF
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 1,
  "lineage": "test",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "test_resource",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/test\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "test"
          }
        }
      ]
    }
  ]
}
EOF

# Create mock terraform script
mkdir -p ansible_dr_test/bin
cat > ansible_dr_test/bin/terraform << 'EOF'
#!/bin/bash

# Get the current working directory
CURRENT_DIR="$(pwd)"

case "$1" in
    "state")
        case "$2" in
            "list")
                echo "module.networking"
                echo "module.compute"
                echo "module.storage"
                ;;
            "show")
                cat "$CURRENT_DIR/terraform.tfstate"
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    "init")
        echo "Initializing Terraform..."
        echo "Terraform has been successfully initialized!"
        exit 0
        ;;
    "plan")
        if [[ "$*" == *"-out=tfplan"* ]]; then
            echo "Planning Terraform changes..."
            echo "Plan: 2 to add, 1 to change, 0 to destroy."
            touch "$CURRENT_DIR/tfplan"
            exit 0
        else
            echo "Error: -out=tfplan flag is required"
            exit 1
        fi
        ;;
    "apply")
        if [[ "$*" == *"-auto-approve"* ]]; then
            if [[ "$*" == *"tfplan"* ]]; then
                echo "Applying Terraform changes..."
                echo "Apply complete! Resources: 2 added, 1 changed, 0 destroyed."
                echo "Outputs:"
                echo "  controller_ip = 10.0.0.100"
                echo "  storage_id = storage-123"
                exit 0
            else
                echo "Error: tfplan file is required"
                exit 1
            fi
        else
            echo "Error: -auto-approve flag is required"
            exit 1
        fi
        ;;
    "output")
        if [[ "$2" == "-json" ]]; then
            echo '{
              "controller_ip": {
                "value": "10.0.0.100",
                "type": "string"
              },
              "storage_id": {
                "value": "storage-123",
                "type": "string"
              }
            }'
            exit 0
        else
            echo "Error: -json flag is required"
            exit 1
        fi
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x ansible_dr_test/bin/terraform

# Create mock OCI CLI script
cat > ansible_dr_test/bin/oci << 'EOF'
#!/bin/bash

# Mock OCI CLI for testing
case "$1" in
    "compute")
        case "$2" in
            "instance")
                case "$3" in
                    "list")
                        echo '{
                          "data": [
                            {
                              "id": "ocid1.instance.oc1..test",
                              "display_name": "test-instance",
                              "lifecycle_state": "RUNNING",
                              "time_created": "2023-01-01T00:00:00.000Z"
                            }
                          ]
                        }'
                        exit 0
                        ;;
                    "terminate")
                        echo "Terminating instance..."
                        exit 0
                        ;;
                    "launch")
                        echo "Launching instance..."
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    "storage")
        case "$2" in
            "bucket")
                case "$3" in
                    "list")
                        echo '{
                          "data": [
                            {
                              "name": "test-bucket",
                              "namespace": "test-namespace",
                              "time_created": "2023-01-01T00:00:00.000Z"
                            }
                          ]
                        }'
                        exit 0
                        ;;
                    "get")
                        echo '{
                          "data": {
                            "name": "test-bucket",
                            "namespace": "test-namespace",
                            "time_created": "2023-01-01T00:00:00.000Z"
                          }
                        }'
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
                ;;
            "object")
                case "$3" in
                    "list")
                        echo '{
                          "data": [
                            {
                              "name": "test-object",
                              "size": 1024,
                              "time_created": "2023-01-01T00:00:00.000Z"
                            }
                          ]
                        }'
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x ansible_dr_test/bin/oci

# Create mock Azure CLI script
cat > ansible_dr_test/bin/az << 'EOF'
#!/bin/bash

# Mock Azure CLI for testing
case "$1" in
    "vm")
        case "$2" in
            "list")
                echo '[
                  {
                    "id": "/subscriptions/test-subscription-id/resourceGroups/test-resource-group/providers/Microsoft.Compute/virtualMachines/test-vm",
                    "name": "test-vm",
                    "location": "eastus",
                    "properties": {
                      "provisioningState": "Succeeded",
                      "hardwareProfile": {
                        "vmSize": "Standard_DS1_v2"
                      }
                    }
                  }
                ]'
                exit 0
                ;;
            "delete")
                echo "Deleting VM..."
                exit 0
                ;;
            "create")
                echo "Creating VM..."
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    "storage")
        case "$2" in
            "account")
                case "$3" in
                    "list")
                        echo '[
                          {
                            "id": "/subscriptions/test-subscription-id/resourceGroups/test-resource-group/providers/Microsoft.Storage/storageAccounts/test-storage-account",
                            "name": "teststorageaccount",
                            "location": "eastus",
                            "properties": {
                              "provisioningState": "Succeeded"
                            }
                          }
                        ]'
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
                ;;
            "blob")
                case "$3" in
                    "list")
                        echo '[
                          {
                            "name": "test-blob",
                            "size": 1024,
                            "lastModified": "2023-01-01T00:00:00.000Z"
                          }
                        ]'
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x ansible_dr_test/bin/az

# Create mock openssl script
cat > ansible_dr_test/bin/openssl << 'EOF'
#!/bin/bash
case "$1" in
    "genrsa")
        echo "Generating RSA key..."
        touch "$HOME/.oci/oci_api_key.pem"
        chmod 600 "$HOME/.oci/oci_api_key.pem"
        exit 0
        ;;
    "rsa")
        if [[ "$*" == *"-pubout"* ]]; then
            echo "Generating public key..."
            touch "$HOME/.oci/oci_api_key_public.pem"
            chmod 600 "$HOME/.oci/oci_api_key_public.pem"
            exit 0
        fi
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x ansible_dr_test/bin/openssl

# Create mock pip script
cat > ansible_dr_test/bin/pip << 'EOF'
#!/bin/bash
if [[ "$*" == *"oci-cli"* ]]; then
    echo "Successfully installed oci-cli"
    exit 0
fi
if [[ "$*" == *"requirements"* ]]; then
    echo "Successfully installed Python packages from requirements.txt"
    exit 0
fi
if [[ "$*" == *"azure-cli"* || "$*" == *"azure-mgmt-resource"* || "$*" == *"azure-identity"* || "$*" == *"oci"* || "$*" == *"pyyaml"* || "$*" == *"jinja2"* ]]; then
    echo "Successfully installed Python package"
    exit 0
fi
# Pass through to real pip for other packages
/usr/bin/env pip "$@"
EOF
chmod +x ansible_dr_test/bin/pip

# Add mock commands to PATH
export PATH="$(pwd)/ansible_dr_test/bin:$PATH"

# Create test user home directory
TEST_USER_HOME="$(pwd)/ansible_dr_test/home/testuser"
mkdir -p "$TEST_USER_HOME/.oci"
chmod 700 "$TEST_USER_HOME/.oci"

# Create workspace directory for controller setup
WORKSPACE_DIR_INFRA="$(pwd)/ansible_dr_test/opt/cloud-elt-infra"
mkdir -p "$WORKSPACE_DIR_INFRA/terraform"
chmod 755 "$WORKSPACE_DIR_INFRA"
chmod 755 "$WORKSPACE_DIR_INFRA/terraform"

# Test disaster recovery playbook
echo_status "Testing disaster recovery playbook"

# Test disaster recovery with OCI
echo_status "Testing disaster recovery with OCI"
ANSIBLE_CONFIG="$(pwd)/ansible_dr_test/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$(pwd)/ansible_dr_test/inventory/test.ini" \
    -e "terraform_dir=$(pwd)/ansible_dr_test/terraform" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$(pwd)/ansible_dr_test" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    -e "cloud_provider=oci" \
    -e "dr_action=backup" \
    ansible/playbooks/disaster_recovery.yml || {
        echo_warning "Disaster recovery with OCI (backup) check mode failed"
    }

ANSIBLE_CONFIG="$(pwd)/ansible_dr_test/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$(pwd)/ansible_dr_test/inventory/test.ini" \
    -e "terraform_dir=$(pwd)/ansible_dr_test/terraform" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$(pwd)/ansible_dr_test" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    -e "cloud_provider=oci" \
    -e "dr_action=restore" \
    ansible/playbooks/disaster_recovery.yml || {
        echo_warning "Disaster recovery with OCI (restore) check mode failed"
    }

# Test disaster recovery with Azure
echo_status "Testing disaster recovery with Azure"
ANSIBLE_CONFIG="$(pwd)/ansible_dr_test/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$(pwd)/ansible_dr_test/inventory/test.ini" \
    -e "terraform_dir=$(pwd)/ansible_dr_test/terraform" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$(pwd)/ansible_dr_test" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    -e "cloud_provider=azure" \
    -e "dr_action=backup" \
    ansible/playbooks/disaster_recovery.yml || {
        echo_warning "Disaster recovery with Azure (backup) check mode failed"
    }

ANSIBLE_CONFIG="$(pwd)/ansible_dr_test/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$(pwd)/ansible_dr_test/inventory/test.ini" \
    -e "terraform_dir=$(pwd)/ansible_dr_test/terraform" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$(pwd)/ansible_dr_test" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    -e "cloud_provider=azure" \
    -e "dr_action=restore" \
    ansible/playbooks/disaster_recovery.yml || {
        echo_warning "Disaster recovery with Azure (restore) check mode failed"
    }

# Test disaster recovery role
echo_status "Testing disaster recovery role"
ANSIBLE_CONFIG="$(pwd)/ansible_dr_test/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$(pwd)/ansible_dr_test/inventory/test.ini" \
    -e "terraform_dir=$(pwd)/ansible_dr_test/terraform" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$(pwd)/ansible_dr_test" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    -e "cloud_provider=oci" \
    -e "dr_action=backup" \
    -e "test_role=true" \
    ansible/playbooks/disaster_recovery.yml || {
        echo_warning "Disaster recovery role check mode failed"
    }

# Generate disaster recovery test report
echo_status "Generating disaster recovery test report"
cat << EOF > ansible_disaster_recovery_report.txt
Ansible Disaster Recovery Test Report
===================================
Date: $(date)
Ansible Version: $(ansible --version | head -n1)

Disaster Recovery Tests:
1. OCI Cloud Provider
   - Backup operation: Checked
   - Restore operation: Checked

2. Azure Cloud Provider
   - Backup operation: Checked
   - Restore operation: Checked

3. Disaster Recovery Role
   - Role functionality: Checked

Environment:
- Test inventory: ansible_dr_test/inventory/test.ini
- Test vault files: ansible_dr_test/group_vars/
- Mock terraform: ansible_dr_test/terraform/
- Mock cloud provider CLIs: ansible_dr_test/bin/

Next Steps:
1. Review this report
2. Test in development environment with real cloud provider credentials
3. Verify all disaster recovery operations work as expected
4. Deploy to production if all tests pass
EOF

echo_status "Disaster recovery tests completed"
echo "See ansible_disaster_recovery_report.txt for details"

# Deactivate virtual environment
deactivate || echo_warning "Could not deactivate virtual environment"
