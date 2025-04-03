#!/bin/bash

# Test Ansible Playbook Script
# ---------------------------
# This script runs a playbook in a test environment and cleans up afterward.

set -e  # Exit on error

# Configuration
TEST_ENV="test"
PLAYBOOK=$1
INVENTORY="ansible/inventories/$TEST_ENV/hosts.yml"

# Create test environment
echo "Setting up test environment..."
mkdir -p "ansible/inventories/$TEST_ENV"
cp "ansible/inventories/example/hosts.yml" "$INVENTORY"

# Create test vault
echo "Setting up test vault..."
mkdir -p "ansible/group_vars/$TEST_ENV"
cp "ansible/group_vars/all/vault.yml.example" "ansible/group_vars/$TEST_ENV/vault.yml"

# Run the playbook
echo "Running playbook: $PLAYBOOK"
ansible-playbook "$PLAYBOOK" -i "$INVENTORY" --ask-vault-pass

# Verify results
echo "Verifying results..."

# 1. Check if required files exist
echo "Checking for required files..."
ansible -i "$INVENTORY" controller -m stat -a "path=/etc/ansible/facts.d/cloud.fact" | grep -q "exists.*true" || {
    echo "Error: Required file not found"
    exit 1
}

# 2. Check if services are running
echo "Checking service status..."
ansible -i "$INVENTORY" controller -m systemd -a "name=ansible state=started" | grep -q "active.*running" || {
    echo "Error: Required service not running"
    exit 1
}

# 3. Verify Python environment
echo "Checking Python environment..."
ansible -i "$INVENTORY" controller -m shell -a "python3 --version && pip3 list" | grep -q "Python 3" || {
    echo "Error: Python environment not properly set up"
    exit 1
}

# 4. Check cloud provider tools
echo "Checking cloud provider tools..."
if grep -q "azure" "$PLAYBOOK"; then
    ansible -i "$INVENTORY" controller -m shell -a "az --version" | grep -q "azure-cli" || {
        echo "Error: Azure CLI not properly installed"
        exit 1
    }
elif grep -q "oci" "$PLAYBOOK"; then
    ansible -i "$INVENTORY" controller -m shell -a "oci --version" | grep -q "Oracle Cloud Infrastructure CLI" || {
        echo "Error: OCI CLI not properly installed"
        exit 1
    }
fi

# 5. Verify Terraform installation
echo "Checking Terraform installation..."
ansible -i "$INVENTORY" controller -m shell -a "terraform --version" | grep -q "Terraform v" || {
    echo "Error: Terraform not properly installed"
    exit 1
}

# 6. Check SSH connectivity
echo "Checking SSH connectivity..."
ansible -i "$INVENTORY" controller -m ping || {
    echo "Error: SSH connectivity test failed"
    exit 1
}

# Cleanup
echo "Cleaning up test environment..."
rm -rf "ansible/inventories/$TEST_ENV"
rm -rf "ansible/group_vars/$TEST_ENV"

echo "Test completed successfully!" 