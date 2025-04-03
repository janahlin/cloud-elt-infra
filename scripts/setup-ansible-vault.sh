#!/bin/bash
# Script to set up an Ansible Vault for storing sensitive credentials

set -e

HEADER_COLOR="\033[1;34m"
SUCCESS_COLOR="\033[1;32m"
ERROR_COLOR="\033[1;31m"
WARNING_COLOR="\033[1;33m"
RESET_COLOR="\033[0m"

title() {
  echo -e "${HEADER_COLOR}==== $1 ====${RESET_COLOR}"
}

success() {
  echo -e "${SUCCESS_COLOR}✓ $1${RESET_COLOR}"
}

error() {
  echo -e "${ERROR_COLOR}✗ $1${RESET_COLOR}"
  exit 1
}

warning() {
  echo -e "${WARNING_COLOR}! $1${RESET_COLOR}"
}

check_ansible() {
  if ! command -v ansible &> /dev/null; then
    error "Ansible is required but not found. Please install Ansible or run setup-venv.sh first."
  fi
  
  if ! command -v ansible-vault &> /dev/null; then
    error "ansible-vault command not found. Please check your Ansible installation."
  fi
  
  success "Ansible is installed"
}

setup_vault() {
  ENV="$1"
  if [ -z "$ENV" ]; then
    ENV="dev"
  fi
  
  title "Setting up Ansible Vault for $ENV environment"
  
  # Create directory structure
  DIR="ansible/group_vars/$ENV"
  mkdir -p "$DIR"
  
  # Set vault password file name
  VAULT_PASS_FILE=".vault_pass_${ENV}.txt"
  
  # Check if vault password file exists
  if [ -f "$VAULT_PASS_FILE" ]; then
    warning "Vault password file $VAULT_PASS_FILE already exists"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Operation cancelled"
      exit 1
    fi
  fi
  
  # Get vault password
  read -s -p "Enter a secure password for the vault: " VAULT_PASS
  echo
  read -s -p "Enter the vault password again: " VAULT_PASS_CONFIRM
  echo

  if [ "$VAULT_PASS" != "$VAULT_PASS_CONFIRM" ]; then
    error "Passwords do not match"
    exit 1
  fi

  # Save vault password
  echo "$VAULT_PASS" > "$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"
  success "Vault password saved to $VAULT_PASS_FILE"

  # Add to .gitignore if not already there
  if ! grep -q "$VAULT_PASS_FILE" .gitignore; then
    echo "$VAULT_PASS_FILE" >> .gitignore
    success "Added $VAULT_PASS_FILE to .gitignore"
  fi
  
  # Check if vault file already exists
  VAULT_FILE="$DIR/vault.yml"
  if [ -f "$VAULT_FILE" ]; then
    warning "Vault file already exists: $VAULT_FILE"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting without overwriting."
      exit 0
    fi
  fi
  
  # Copy example file if it exists
  if [ -f "ansible/group_vars/all/vault.yml.example" ]; then
    cp "ansible/group_vars/all/vault.yml.example" "$VAULT_FILE.tmp"
    success "Created vault file from example"
  else
    # Create a basic vault file template
    cat > "$VAULT_FILE.tmp" << EOF
# Azure credentials
vault_azure_subscription_id: ""
vault_azure_tenant_id: ""
vault_azure_client_id: ""         # Required for Service Principal auth
vault_azure_client_secret: ""      # Required for Service Principal auth

# Authentication method for Azure
use_service_principal: false  # Set to true to use Service Principal, false for Managed Identity

# OCI credentials
vault_oci_tenancy_ocid: ""
vault_oci_user_ocid: ""
vault_oci_fingerprint: ""
EOF
    success "Created vault file template"
  fi
  
  # Prompt to edit the vault file
  echo ""
  echo "Now you need to edit the vault file and add your credentials."
  read -p "Would you like to edit it now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-vi} "$VAULT_FILE.tmp"
  fi
  
  # Encrypt the vault file using vault-id
  ansible-vault encrypt --vault-id "$ENV@$VAULT_PASS_FILE" "$VAULT_FILE.tmp" --output="$VAULT_FILE"
  rm "$VAULT_FILE.tmp"
  success "Vault file encrypted and saved to $VAULT_FILE"
  
  # Display usage instructions
  echo
  echo "To view the vault file:"
  echo "    ansible-vault view --vault-id $ENV@$VAULT_PASS_FILE $VAULT_FILE"
  echo
  echo "To edit the vault file:"
  echo "    ansible-vault edit --vault-id $ENV@$VAULT_PASS_FILE $VAULT_FILE"
  echo
  echo "To run a playbook:"
  echo "    ansible-playbook -i ansible/inventories/$ENV/hosts.yml --vault-id $ENV@$VAULT_PASS_FILE ansible/playbooks/deploy_azure_infra.yml"
}

# Main script execution
check_ansible
setup_vault "$1" 