#!/bin/bash

# Test Terraform Script
# --------------------
# This script runs Terraform in a test environment and cleans up afterward.

set -e  # Exit on error

# Configuration
TEST_ENV="test"
TF_DIR=$1  # Directory containing Terraform configuration

# Create test environment
echo "Setting up test environment..."
mkdir -p "terraform/environments/$TEST_ENV"
cp -r "$TF_DIR"/* "terraform/environments/$TEST_ENV/"

# Initialize Terraform
echo "Initializing Terraform..."
cd "terraform/environments/$TEST_ENV"
terraform init

# Run plan
echo "Running Terraform plan..."
terraform plan

# Optional: Run apply and destroy
if [ "$2" == "--apply" ]; then
    echo "Applying Terraform configuration..."
    terraform apply -auto-approve
    
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
    if grep -q "azure" "$TF_DIR/main.tf"; then
        # Azure-specific checks
        terraform output | grep -q "resource_group_name" || {
            echo "Error: Azure resource group not created"
            exit 1
        }
        terraform output | grep -q "storage_account_name" || {
            echo "Error: Azure storage account not created"
            exit 1
        }
    elif grep -q "oci" "$TF_DIR/main.tf"; then
        # OCI-specific checks
        terraform output | grep -q "compartment_id" || {
            echo "Error: OCI compartment not created"
            exit 1
        }
        terraform output | grep -q "vcn_id" || {
            echo "Error: OCI VCN not created"
            exit 1
        }
    fi

    # 3. Check for any errors in the state
    echo "Checking Terraform state..."
    terraform state list | grep -q "error" && {
        echo "Error: Found errors in Terraform state"
        exit 1
    }

    # 4. Verify resource dependencies
    echo "Verifying resource dependencies..."
    terraform graph | grep -q "->" || {
        echo "Error: Resource dependencies not properly configured"
        exit 1
    }

    # 5. Check for any warnings in the plan
    echo "Checking for warnings..."
    terraform plan -detailed-exitcode > /dev/null 2>&1
    if [ $? -eq 2 ]; then
        echo "Warning: Plan would make changes"
    fi

    # Cleanup
    echo "Destroying test environment..."
    terraform destroy -auto-approve
fi

# Cleanup
echo "Cleaning up test environment..."
cd ../..
rm -rf "terraform/environments/$TEST_ENV"

echo "Test completed successfully!" 