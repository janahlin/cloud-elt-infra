#!/bin/bash

# Test Ansible Playbook Script
# ---------------------------
# This script runs a playbook in a test environment and cleans up afterward.

set -e  # Exit on error

# Configuration
TEST_ENV=${1:-"dev"}  # Use dev as default if not provided
MODE=${3:-"check"}    # "check" or "apply"

echo "Starting playbook test with ENV=$TEST_ENV, MODE=$MODE"

# Set Ansible config path
export ANSIBLE_CONFIG="$(pwd)/ansible/ansible.cfg"

# Create test environment
TEST_DIR="ansible/inventories/test_${TEST_ENV}"
mkdir -p "$TEST_DIR/group_vars/all"

# Create a basic vars.yml file
cat > "$TEST_DIR/group_vars/all/vars.yml" << EOF
---
# Test variables
env_name: "${TEST_ENV}"
cloud_provider: "azure"
resource_prefix: "elt"
EOF

# Create test inventory
cat > "$TEST_DIR/hosts.yml" << EOF
---
all:
  hosts:
    localhost:
      ansible_connection: local
  children:
    controller:
      hosts:
        localhost:
EOF

# Create a simple test playbook
TEST_PLAYBOOK="$TEST_DIR/test_playbook.yml"
cat > "$TEST_PLAYBOOK" << EOF
---
- name: Test Playbook
  hosts: controller
  gather_facts: no

  tasks:
    - name: Display test message
      debug:
        msg: "Running test playbook for {{ env_name }} environment"
EOF

# Run the test playbook
echo "Running test playbook..."
ansible-playbook "$TEST_PLAYBOOK" -i "$TEST_DIR/hosts.yml" ${MODE:+--$MODE} || {
    echo "Playbook execution failed"
    rm -rf "$TEST_DIR"
    exit 1
}

# Cleanup
echo "Cleaning up test environment..."
rm -rf "$TEST_DIR"

echo "Playbook test completed successfully!"
