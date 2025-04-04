#!/bin/bash

# Script to test Ansible playbook execution with the upgraded version

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}=== $1 ===${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if playbook path is provided
if [ $# -eq 0 ]; then
    print_error "Please provide the path to the playbook"
fi

PLAYBOOK_PATH="$1"
WORKSPACE_DIR="$(pwd)"

# Create virtual environment
VENV_DIR="$WORKSPACE_DIR/ansible_test_venv"
print_status "Creating virtual environment at $VENV_DIR"
python3 -m venv "$VENV_DIR" || print_error "Failed to create virtual environment"

# Activate virtual environment
source "$VENV_DIR/bin/activate" || print_error "Failed to activate virtual environment"

# Upgrade pip first
print_status "Upgrading pip"
python3 -m pip install --upgrade pip || print_error "Failed to upgrade pip"

# Install packages
print_status "Installing Ansible packages"
pip install ansible-core==2.17.10 ansible==10.7.0 ansible-compat==25.1.5 oci-cli || print_error "Failed to install packages"

# Create test environment structure
TEST_ENV_DIR="$VENV_DIR/ansible"
mkdir -p "$TEST_ENV_DIR"

# Copy original ansible directory structure
print_status "Creating test environment"
cp -r "$WORKSPACE_DIR/ansible/roles" "$TEST_ENV_DIR/"
cp -r "$WORKSPACE_DIR/ansible/playbooks" "$TEST_ENV_DIR/"
cp "$WORKSPACE_DIR/ansible/ansible.cfg" "$TEST_ENV_DIR/"

# Create test inventory
INVENTORY_DIR="$TEST_ENV_DIR/inventory"
mkdir -p "$INVENTORY_DIR"
cat > "$INVENTORY_DIR/test.ini" << EOF
[controller]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3 ansible_user=testuser

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Create test terraform directory and files
TERRAFORM_DIR="$VENV_DIR/terraform"
mkdir -p "$TERRAFORM_DIR"

# Create terraform state file
cat > "$TERRAFORM_DIR/terraform.tfstate" << EOF
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
MOCK_DIR="$VENV_DIR/bin"
mkdir -p "$MOCK_DIR"
cat > "$MOCK_DIR/terraform" << 'EOF'
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
chmod +x "$MOCK_DIR/terraform"

# Create mock openssl script
cat > "$MOCK_DIR/openssl" << 'EOF'
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
chmod +x "$MOCK_DIR/openssl"

# Create mock pip script
cat > "$MOCK_DIR/pip" << 'EOF'
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
chmod +x "$MOCK_DIR/pip"

# Add mock commands to PATH
export PATH="$MOCK_DIR:$PATH"

# Create test vault files and variables
GROUP_VARS_DIR="$TEST_ENV_DIR/group_vars"
mkdir -p "$GROUP_VARS_DIR/dev"
mkdir -p "$GROUP_VARS_DIR/prod"

# Create mock vault files
cat > "$GROUP_VARS_DIR/dev/vault.yml" << EOF
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

cat > "$GROUP_VARS_DIR/prod/vault.yml" << EOF
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

# Create templates directory and terraform.tfvars template
TEMPLATES_DIR="$TEST_ENV_DIR/templates"
mkdir -p "$TEMPLATES_DIR"
cat > "$TEMPLATES_DIR/terraform.tfvars.j2" << EOF
# OCI Configuration
oci_tenancy_ocid = "{{ oci_config.tenancy }}"
oci_user_ocid = "{{ oci_config.user }}"
oci_fingerprint = "{{ oci_config.fingerprint }}"
oci_private_key_path = "{{ oci_config.key_file }}"
oci_region = "{{ oci_config.region }}"

# Azure Configuration
azure_subscription_id = "{{ azure_config.subscription_id }}"
azure_client_id = "{{ azure_config.client_id }}"
azure_client_secret = "{{ azure_config.client_secret }}"
azure_tenant_id = "{{ azure_config.tenant_id }}"
EOF

# Copy terraform.tfvars template to infrastructure_deploy role
INFRA_DEPLOY_TEMPLATES_DIR="$TEST_ENV_DIR/roles/infrastructure_deploy/templates"
mkdir -p "$INFRA_DEPLOY_TEMPLATES_DIR"
cp "$TEMPLATES_DIR/terraform.tfvars.j2" "$INFRA_DEPLOY_TEMPLATES_DIR/"

# Create OCI tools role templates directory and config template
OCI_TOOLS_TEMPLATES_DIR="$TEST_ENV_DIR/roles/oci_tools/templates"
mkdir -p "$OCI_TOOLS_TEMPLATES_DIR"
cat > "$OCI_TOOLS_TEMPLATES_DIR/oci_config.j2" << EOF
[DEFAULT]
user={{ oci_config.user }}
fingerprint={{ oci_config.fingerprint }}
tenancy={{ oci_config.tenancy }}
region={{ oci_config.region }}
key_file={{ oci_config.key_file }}
EOF

# Create controller setup role templates directory and templates
CONTROLLER_SETUP_TEMPLATES_DIR="$TEST_ENV_DIR/roles/controller_setup/templates"
mkdir -p "$CONTROLLER_SETUP_TEMPLATES_DIR"
cat > "$CONTROLLER_SETUP_TEMPLATES_DIR/deployment_script.j2" << 'EOF'
#!/bin/bash
set -e

# Deployment script for Cloud ELT Infrastructure
cd /opt/cloud-elt-infra/terraform

# Check if tfvars file exists
if [ ! -f "terraform.tfvars" ]; then
  echo "Creating terraform.tfvars from example file..."
  cp terraform.tfvars.example terraform.tfvars
  echo "Please edit terraform.tfvars with your specific values before deploying."
  exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan the deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply the plan? (y/n): " confirm
if [[ $confirm == "y" || $confirm == "Y" ]]; then
  echo "Applying Terraform plan..."
  terraform apply tfplan

  echo "Deployment complete!"
else
  echo "Deployment canceled."
fi
EOF

# Create vault password files in the correct location
echo "test_password" > "$TEST_ENV_DIR/.vault_pass_dev.txt"
echo "test_password" > "$TEST_ENV_DIR/.vault_pass_prod.txt"

# Update ansible.cfg for test environment
sed -i "s|inventory = ./inventories|inventory = ./inventory|" "$TEST_ENV_DIR/ansible.cfg"
sed -i "s|roles_path = ./roles|roles_path = $TEST_ENV_DIR/roles|" "$TEST_ENV_DIR/ansible.cfg"
sed -i "s|collections_paths = ./venv/lib/python3.10/site-packages/ansible_collections:~/.ansible/collections|collections_paths = $VENV_DIR/lib/python3.10/site-packages/ansible_collections:~/.ansible/collections|" "$TEST_ENV_DIR/ansible.cfg"
sed -i "s|vault_identity_list = dev@.vault_pass_dev.txt, prod@.vault_pass_prod.txt|vault_identity_list = dev@$TEST_ENV_DIR/.vault_pass_dev.txt, prod@$TEST_ENV_DIR/.vault_pass_prod.txt|" "$TEST_ENV_DIR/ansible.cfg"

# Create mock package manager script
cat > "$MOCK_DIR/apt-get" << 'EOF'
#!/bin/bash
if [[ "$*" == *"install"* ]]; then
    echo "Installing packages..."
    exit 0
fi
if [[ "$*" == *"update"* ]]; then
    echo "Updating package lists..."
    exit 0
fi
echo "Mock apt-get $*"
exit 0
EOF
chmod +x "$MOCK_DIR/apt-get"

cat > "$MOCK_DIR/apt-key" << 'EOF'
#!/bin/bash
if [[ "$*" == *"https://apt.releases.hashicorp.com/gpg"* ]]; then
    echo "Adding HashiCorp GPG key..."
    exit 0
fi
echo "Mock apt-key $*"
exit 0
EOF
chmod +x "$MOCK_DIR/apt-key"

# Create mock apt-add-repository script
cat > "$MOCK_DIR/add-apt-repository" << 'EOF'
#!/bin/bash
if [[ "$*" == *"hashicorp"* ]]; then
    echo "Adding HashiCorp repository..."
    exit 0
fi
echo "Mock add-apt-repository $*"
exit 0
EOF
chmod +x "$MOCK_DIR/add-apt-repository"

# Create mock git script
cat > "$MOCK_DIR/git" << 'EOF'
#!/bin/bash
if [[ "$*" == *"ls-remote"* ]]; then
    # Mock successful ls-remote response
    echo "a1b2c3d4e5f6g7h8i9j0 refs/heads/main"
    exit 0
fi
if [[ "$*" == *"clone"* ]]; then
    echo "Mock: Cloning repository..."
    # Extract destination directory from the clone command
    dest_dir=""
    for arg in "$@"; do
        if [[ "$prev_arg" == "dest" ]]; then
            dest_dir="$arg"
            break
        fi
        prev_arg="$arg"
    done
    if [[ -n "$dest_dir" ]]; then
        # Create directory structure
        mkdir -p "$dest_dir"
        # Create a mock .git directory
        mkdir -p "$dest_dir/.git"
        # Create a mock git config
        cat > "$dest_dir/.git/config" << 'GIT_CONFIG'
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = https://github.com/mock/cloud-elt-infra.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
        remote = origin
        merge = refs/heads/main
GIT_CONFIG
        # Copy the current workspace files to simulate a clone
        cp -r "$WORKSPACE_DIR/ansible" "$dest_dir/"
        cp -r "$WORKSPACE_DIR/scripts" "$dest_dir/"
        cp -r "$WORKSPACE_DIR/terraform" "$dest_dir/" 2>/dev/null || true
        echo "Mock: Repository cloned successfully"
    fi
    exit 0
fi
echo "Mock git $*"
exit 0
EOF
chmod +x "$MOCK_DIR/git"

# Create test user home directory
TEST_USER_HOME="$VENV_DIR/home/testuser"
mkdir -p "$TEST_USER_HOME/.oci"
chmod 700 "$TEST_USER_HOME/.oci"

# Create workspace directory for controller setup
WORKSPACE_DIR_INFRA="$VENV_DIR/opt/cloud-elt-infra"
mkdir -p "$WORKSPACE_DIR_INFRA/terraform"
chmod 755 "$WORKSPACE_DIR_INFRA"
chmod 755 "$WORKSPACE_DIR_INFRA/terraform"

# Change to terraform directory before running playbook
cd "$TERRAFORM_DIR" || print_error "Failed to change to terraform directory"

# Run playbook in check mode first
print_status "Running playbook in check mode"
ANSIBLE_CONFIG="$TEST_ENV_DIR/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    --check \
    -i "$INVENTORY_DIR/test.ini" \
    -e "terraform_dir=$TERRAFORM_DIR" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$TEST_ENV_DIR" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    "$TEST_ENV_DIR/playbooks/$(basename $PLAYBOOK_PATH)" || print_error "Playbook check mode failed"

print_status "Check mode passed, running playbook"

# Run playbook for real
ANSIBLE_CONFIG="$TEST_ENV_DIR/ansible.cfg" \
HOME="$TEST_USER_HOME" \
ansible-playbook \
    -i "$INVENTORY_DIR/test.ini" \
    -e "terraform_dir=$TERRAFORM_DIR" \
    -e "environment=dev" \
    -e "env=dev" \
    -e "ansible_dir=$TEST_ENV_DIR" \
    -e "auto_approve=true" \
    -e "workspace_dir=$WORKSPACE_DIR_INFRA" \
    "$TEST_ENV_DIR/playbooks/$(basename $PLAYBOOK_PATH)" || print_error "Playbook execution failed"

print_status "Playbook execution completed successfully"

# Change back to workspace directory
cd "$WORKSPACE_DIR" || print_error "Failed to change back to workspace directory"

# Deactivate virtual environment
deactivate

print_status "Test completed successfully"
