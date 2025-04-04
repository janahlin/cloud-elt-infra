#!/bin/bash

# Test Terraform Script
# --------------------
# This script runs Terraform in a test environment and cleans up afterward.

set -e  # Exit on error

# Configuration
TEST_ENV=${1:-"dev"}  # Use dev as default environment if not provided
TF_DIR=${2:-"terraform"}  # Default to main terraform directory
MODE=${3:-"plan"}  # "plan" or "apply"

# Generate terraform.tfvars if it doesn't exist
if [ ! -f "$TF_DIR/terraform.tfvars" ]; then
    echo "Generating terraform.tfvars for $TEST_ENV environment..."
    ./scripts/generate-terraform-vars.sh $TEST_ENV
fi

# Create test environment
echo "Setting up test environment..."
TEST_DIR="$TF_DIR/test_$TEST_ENV"
mkdir -p "$TEST_DIR"

# Copy terraform files to test directory
cp "$TF_DIR/terraform.tfvars" "$TEST_DIR/"
cp "$TF_DIR"/*.tf "$TEST_DIR/"

# Copy modules directory with proper structure
echo "Copying module directories..."
mkdir -p "$TEST_DIR/modules"
cp -r "$TF_DIR/modules" "$TEST_DIR/" 2>/dev/null || echo "No modules directory found"

# Copy environments directory with proper structure
mkdir -p "$TEST_DIR/environments/azure"
mkdir -p "$TEST_DIR/environments/oci"
cp -r "$TF_DIR/environments/azure"/* "$TEST_DIR/environments/azure/" 2>/dev/null || echo "No Azure environment directory found"
cp -r "$TF_DIR/environments/oci"/* "$TEST_DIR/environments/oci/" 2>/dev/null || echo "No OCI environment directory found"

# Initialize Terraform
echo "Initializing Terraform..."
cd "$TEST_DIR"
terraform init

# Run plan with terraform.tfvars
echo "Running Terraform plan..."
terraform plan -var-file=terraform.tfvars

# Optional: Run apply and destroy
if [ "$MODE" == "apply" ]; then
    echo "Applying Terraform configuration..."
    terraform apply -auto-approve -var-file=terraform.tfvars

    # Verify results
    echo "Verifying results..."

    # 1. Check if resources were created
    echo "Checking resource creation..."
    terraform state list | grep -q "module" || {
        echo "Error: No resources were created"
        exit 1
    }

    # 2. Verify resource attributes
    echo "Verifying resource attributes..."
    if terraform state list | grep -q "azurerm"; then
        # Azure-specific checks
        echo "Checking Azure resources..."
        terraform state list | grep -q "azurerm_resource_group" || {
            echo "Warning: Azure resource group not found in state"
        }
    elif terraform state list | grep -q "oci"; then
        # OCI-specific checks
        echo "Checking OCI resources..."
        terraform state list | grep -q "oci_core_vcn" || {
            echo "Warning: OCI VCN not found in state"
        }
    fi

    # Cleanup
    echo "Destroying test environment..."
    terraform destroy -auto-approve -var-file=terraform.tfvars
fi

# Cleanup
cd - > /dev/null
echo "Cleaning up test environment..."
rm -rf "$TEST_DIR"

echo "Test completed successfully!"
