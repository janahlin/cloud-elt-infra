#!/bin/bash

set -e

# Colors for output
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

# Clean up temporary files
cleanup_temp_files() {
  title "Cleaning up temporary files"

  # Remove Python cache files
  find . -type d -name "__pycache__" -exec rm -rf {} +
  find . -type f -name "*.pyc" -delete

  # Remove Terraform files
  find . -type f -name "*.tfstate*" -delete
  find . -type d -name ".terraform" -exec rm -rf {} +

  # Remove Ansible files
  find . -type f -name "*.retry" -delete

  success "Temporary files cleaned up"
}

# Clean up test resources
cleanup_test_resources() {
  title "Cleaning up test resources"

  # Check if we're in a test environment
  if [ "$TF_VAR_environment" != "dev" ]; then
    warning "Not in test environment, skipping resource cleanup"
    return
  fi

  # Clean up Terraform resources if they exist
  if [ -d "terraform" ]; then
    cd terraform
    if [ -f "terraform.tfstate" ]; then
      warning "Destroying Terraform resources"
      terraform destroy -auto-approve
    fi
    cd ..
  fi

  success "Test resources cleaned up"
}

# Clean up virtual environments
cleanup_venvs() {
  title "Cleaning up virtual environments"

  # Remove test virtual environments
  if [ -d "ansible_test_venv" ]; then
    rm -rf ansible_test_venv
  fi

  if [ -d "venv" ]; then
    warning "Found main virtual environment"
    read -p "Do you want to remove it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf venv
      success "Main virtual environment removed"
    fi
  fi

  success "Virtual environments cleaned up"
}

# Main cleanup process
main() {
  title "Starting cleanup process"

  cleanup_temp_files
  cleanup_test_resources
  cleanup_venvs

  title "Cleanup completed successfully"
}

# Run main function
main
