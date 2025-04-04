#!/bin/bash
# Validates infrastructure recovery after a disaster recovery event

set -e

# Determine cloud provider from command line or environment variable
CLOUD_PROVIDER=${1:-${CLOUD_PROVIDER:-"azure"}}
ENVIRONMENT=${2:-${ENVIRONMENT:-"dev"}}

echo "===== ELT Infrastructure Recovery Validation ====="
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Environment: $ENVIRONMENT"
echo "=================================================="

# Load configuration
if [ -f "/opt/cloud-elt-infra/config.yml" ]; then
  echo "Loading configuration from config.yml"
  # Simple YAML parser (rudimentary)
  export $(grep -v '^#' /opt/cloud-elt-infra/config.yml | sed 's/: */=/' | sed 's/ *#.*//')
fi

validate_azure() {
  echo "Validating Azure infrastructure..."

  # Check Resource Group
  echo "- Checking Resource Group..."
  RG_EXISTS=$(az group exists --name "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-rg")
  if [ "$RG_EXISTS" = "true" ]; then
    echo "  ✅ Resource Group exists"
  else
    echo "  ❌ Resource Group does not exist"
    exit 1
  fi

  # Check Virtual Machine
  echo "- Checking Virtual Machine..."
  VM_STATUS=$(az vm show -g "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-rg" -n "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-vm" --query "powerState" -o tsv 2>/dev/null || echo "NotFound")
  if [ "$VM_STATUS" = "VM running" ]; then
    echo "  ✅ Virtual Machine is running"
  else
    echo "  ❌ Virtual Machine is not running properly (status: $VM_STATUS)"
  fi

  # Check Storage Account
  echo "- Checking Storage Account..."
  STORAGE_EXISTS=$(az storage account check-name --name "${RESOURCE_PREFIX:-elt}${ENVIRONMENT}storage" --query "nameAvailable" -o tsv)
  if [ "$STORAGE_EXISTS" = "false" ]; then
    echo "  ✅ Storage Account exists"
  else
    echo "  ❌ Storage Account does not exist"
  fi

  # Check Databricks Workspace
  echo "- Checking Databricks Workspace..."
  DATABRICKS_STATUS=$(az databricks workspace show --resource-group "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-rg" --name "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-databricks" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
  if [ "$DATABRICKS_STATUS" = "Succeeded" ]; then
    echo "  ✅ Databricks Workspace is provisioned"
  else
    echo "  ❌ Databricks Workspace is not properly provisioned (status: $DATABRICKS_STATUS)"
  fi

  # Check Data Factory
  echo "- Checking Data Factory..."
  ADF_STATUS=$(az datafactory show --resource-group "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-rg" --factory-name "${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-adf" --query "provisioningState" -o tsv 2>/dev/null || echo "NotFound")
  if [ "$ADF_STATUS" = "Succeeded" ]; then
    echo "  ✅ Data Factory is provisioned"
  else
    echo "  ❌ Data Factory is not properly provisioned (status: $ADF_STATUS)"
  fi
}

validate_oci() {
  echo "Validating OCI infrastructure..."

  # Check Compartment
  echo "- Checking Compartment..."
  COMPARTMENT_NAME="${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}"
  COMPARTMENT_EXISTS=$(oci iam compartment list --name "$COMPARTMENT_NAME" --query "data[0].id" 2>/dev/null || echo "NotFound")
  if [ "$COMPARTMENT_EXISTS" != "NotFound" ]; then
    echo "  ✅ Compartment exists"
    COMPARTMENT_ID=$COMPARTMENT_EXISTS
  else
    echo "  ❌ Compartment does not exist"
    # Use parent compartment as fallback
    COMPARTMENT_ID=$OCI_COMPARTMENT_ID
  fi

  # Check Compute Instance
  echo "- Checking Compute Instance..."
  INSTANCE_NAME="${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-vm"
  INSTANCE_STATUS=$(oci compute instance list --compartment-id "$COMPARTMENT_ID" --display-name "$INSTANCE_NAME" --query "data[0].\"lifecycle-state\"" 2>/dev/null || echo "NotFound")
  if [ "$INSTANCE_STATUS" = "RUNNING" ]; then
    echo "  ✅ Compute Instance is running"
  else
    echo "  ❌ Compute Instance is not running properly (status: $INSTANCE_STATUS)"
  fi

  # Check Object Storage Bucket
  echo "- Checking Object Storage Bucket..."
  BUCKET_NAME="${RESOURCE_PREFIX:-elt}-${ENVIRONMENT}-bucket"
  BUCKET_EXISTS=$(oci os bucket list --compartment-id "$COMPARTMENT_ID" --name "$BUCKET_NAME" --query "data[0].name" 2>/dev/null || echo "NotFound")
  if [ "$BUCKET_EXISTS" != "NotFound" ]; then
    echo "  ✅ Object Storage Bucket exists"
  else
    echo "  ❌ Object Storage Bucket does not exist"
  fi

  # Check Airflow
  echo "- Checking Airflow..."
  # This would be OCI DevOps or other airflow implementation
  echo "  ⚠️ Airflow validation not implemented for OCI"
}

# Run the appropriate validation based on cloud provider
case "$CLOUD_PROVIDER" in
  azure)
    validate_azure
    ;;
  oci)
    validate_oci
    ;;
  *)
    echo "Unsupported cloud provider: $CLOUD_PROVIDER"
    echo "Supported providers: azure, oci"
    exit 1
    ;;
esac

echo ""
echo "===== Validation Summary ====="
echo "Recovery validation completed. See details above."
echo "=============================="
