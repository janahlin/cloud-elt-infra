#!/bin/bash

# Infrastructure Test Script
# ------------------------
# This script tests both Ansible playbooks and Terraform configurations
# in a test environment with cleanup.

set -e  # Exit on error

# Configuration
TEST_ENV="test"
MODE=$1  # "plan" or "apply"

# Test Terraform
echo "Testing Terraform configuration..."
./scripts/test-terraform.sh terraform/environments/azure $MODE

# Test Ansible
echo "Testing Ansible playbooks..."
./scripts/test-playbook.sh ansible/playbooks/deploy_azure_infra.yml

# If in apply mode, verify the entire infrastructure
if [ "$MODE" == "apply" ]; then
    echo "Verifying infrastructure..."

    # 1. Check cloud provider connectivity
    echo "Checking cloud provider connectivity..."
    if [ -f "terraform/environments/azure/main.tf" ]; then
        # Azure checks
        az account show > /dev/null || {
            echo "Error: Azure authentication failed"
            exit 1
        }
        az group list --query "[?name=='$TEST_ENV']" | grep -q "$TEST_ENV" || {
            echo "Error: Azure resource group not found"
            exit 1
        }
    elif [ -f "terraform/environments/oci/main.tf" ]; then
        # OCI checks
        oci iam compartment list > /dev/null || {
            echo "Error: OCI authentication failed"
            exit 1
        }
        oci network vcn list --compartment-id "$(oci iam compartment list --query 'data[0].id' --raw-output)" | grep -q "$TEST_ENV" || {
            echo "Error: OCI VCN not found"
            exit 1
        }
    fi

    # 2. Verify network connectivity
    echo "Checking network connectivity..."
    if [ -f "terraform/environments/azure/main.tf" ]; then
        # Azure network checks
        az network vnet list --query "[?name=='$TEST_ENV']" | grep -q "$TEST_ENV" || {
            echo "Error: Azure VNet not found"
            exit 1
        }
    elif [ -f "terraform/environments/oci/main.tf" ]; then
        # OCI network checks
        oci network subnet list --compartment-id "$(oci iam compartment list --query 'data[0].id' --raw-output)" | grep -q "$TEST_ENV" || {
            echo "Error: OCI subnet not found"
            exit 1
        }
    fi

    # 3. Check storage resources
    echo "Checking storage resources..."
    if [ -f "terraform/environments/azure/main.tf" ]; then
        # Azure storage checks
        az storage account list --query "[?name=='$TEST_ENV']" | grep -q "$TEST_ENV" || {
            echo "Error: Azure storage account not found"
            exit 1
        }
    elif [ -f "terraform/environments/oci/main.tf" ]; then
        # OCI storage checks
        oci os bucket list --compartment-id "$(oci iam compartment list --query 'data[0].id' --raw-output)" | grep -q "$TEST_ENV" || {
            echo "Error: OCI bucket not found"
            exit 1
        }
    fi

    # 4. Verify compute resources
    echo "Checking compute resources..."
    if [ -f "terraform/environments/azure/main.tf" ]; then
        # Azure VM checks
        az vm list --query "[?name=='$TEST_ENV']" | grep -q "$TEST_ENV" || {
            echo "Error: Azure VM not found"
            exit 1
        }
    elif [ -f "terraform/environments/oci/main.tf" ]; then
        # OCI instance checks
        oci compute instance list --compartment-id "$(oci iam compartment list --query 'data[0].id' --raw-output)" | grep -q "$TEST_ENV" || {
            echo "Error: OCI instance not found"
            exit 1
        }
    fi

    # 5. Check service health
    echo "Checking service health..."
    if [ -f "terraform/environments/azure/main.tf" ]; then
        # Azure service checks
        az monitor activity-log list --max-events 10 --query "[?operationName.value=='Microsoft.Compute/virtualMachines/write']" | grep -q "Succeeded" || {
            echo "Error: Azure VM creation not successful"
            exit 1
        }
    elif [ -f "terraform/environments/oci/main.tf" ]; then
        # OCI service checks
        oci compute instance get --instance-id "$(oci compute instance list --compartment-id "$(oci iam compartment list --query 'data[0].id' --raw-output)" --query 'data[0].id' --raw-output)" | grep -q "RUNNING" || {
            echo "Error: OCI instance not running"
            exit 1
        }
    fi
fi

echo "All tests completed successfully!" 