#!/bin/bash
# Script to set up Ansible Vault for secure credential management
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
}

warning() {
  echo -e "${WARNING_COLOR}! $1${RESET_COLOR}"
}

# Check if ansible-vault is available
if ! command -v ansible-vault &> /dev/null; then
  error "ansible-vault command not found. Please install Ansible first."
  exit 1
fi

# Set up environment
ENV="${1:-dev}"
title "Setting up Ansible Vault for $ENV environment"

# Create directories
mkdir -p "ansible/group_vars/$ENV"

# Create vault password file
if [ ! -f ".vault_pass_$ENV.txt" ]; then
  echo "Creating vault password file for $ENV environment"
  read -s -p "Enter a secure password for the vault: " VAULT_PASS
  echo ""
  echo "$VAULT_PASS" > ".vault_pass_$ENV.txt"
  chmod 600 ".vault_pass_$ENV.txt"
  success "Vault password file created: .vault_pass_$ENV.txt"
else
  warning "Vault password file .vault_pass_$ENV.txt already exists"
fi

# Create vault file from template
if [ ! -f "ansible/group_vars/$ENV/vault.yml" ]; then
  echo "Creating vault variables file from template"
  cp "ansible/group_vars/all/vault.yml.example" "ansible/group_vars/$ENV/vault.yml"
  
  # Prompt user to edit the vault file
  read -p "Would you like to edit the vault file now (y/n)? " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-vi} "ansible/group_vars/$ENV/vault.yml"
  fi
  
  # Encrypt the vault file
  ansible-vault encrypt --vault-id "$ENV@.vault_pass_$ENV.txt" "ansible/group_vars/$ENV/vault.yml"
  success "Vault file created and encrypted: ansible/group_vars/$ENV/vault.yml"
else
  warning "Vault file ansible/group_vars/$ENV/vault.yml already exists"
fi

# Update .gitignore to exclude vault password files
if ! grep -q ".vault_pass*.txt" .gitignore 2>/dev/null; then
  echo "" >> .gitignore
  echo "# Ansible vault password files" >> .gitignore
  echo ".vault_pass*.txt" >> .gitignore
  success "Updated .gitignore to exclude vault password files"
fi

title "Vault setup complete"
echo ""
echo "To use the vault:"
echo "  1. View encrypted variables:"
echo "     ansible-vault view --vault-id $ENV@.vault_pass_$ENV.txt ansible/group_vars/$ENV/vault.yml"
echo ""
echo "  2. Edit encrypted variables:"
echo "     ansible-vault edit --vault-id $ENV@.vault_pass_$ENV.txt ansible/group_vars/$ENV/vault.yml"
echo ""
echo "  3. Run playbooks with encrypted variables:"
echo "     ansible-playbook -i ansible/inventories/$ENV/hosts.yml --vault-id $ENV@.vault_pass_$ENV.txt ansible/playbooks/deploy_azure_infra.yml" 