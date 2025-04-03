#!/bin/bash

# Infrastructure Test Script
# ------------------------
# This script tests both Ansible playbooks and Terraform configurations
# in a test environment with cleanup.

set -e  # Exit on error
set -x  # Print commands for debugging

# Configuration
TEST_ENV=${1:-"dev"}  # Use dev as default if not provided
MODE=${2:-"plan"}     # "plan" or "apply" for Terraform

# Generate terraform.tfvars
echo "Generating terraform.tfvars for $TEST_ENV environment..."
./scripts/generate-terraform-vars.sh $TEST_ENV

# Test Terraform
echo "Testing Terraform configuration..."
./scripts/test-terraform.sh "$TEST_ENV" "terraform" "$MODE"

# Test Ansible playbooks
echo "Testing Ansible playbooks..."
ANSIBLE_MODE="check"
if [ "$MODE" == "apply" ]; then
    ANSIBLE_MODE="apply"
fi
./scripts/test-playbook.sh "$TEST_ENV" "$ANSIBLE_MODE"

echo "All tests completed successfully!" 