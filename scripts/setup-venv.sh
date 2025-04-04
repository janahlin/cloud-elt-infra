#!/bin/bash
# Setup script for Python virtual environment

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

# Check for Python 3
check_python() {
  title "Checking Python installation"

  if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    success "Python 3 found: $(python3 --version)"
  elif command -v python &> /dev/null && [[ "$(python --version)" == *"Python 3"* ]]; then
    PYTHON_CMD="python"
    success "Python 3 found: $(python --version)"
  else
    error "Python 3 is required but was not found. Please install Python 3.8 or newer."
  fi

  # Check Python version
  PY_VERSION=$($PYTHON_CMD -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")

  # Parse version major and minor parts
  MAJOR_VERSION=$(echo $PY_VERSION | cut -d. -f1)
  MINOR_VERSION=$(echo $PY_VERSION | cut -d. -f2)

  # Compare version to 3.8
  if [ "$MAJOR_VERSION" -lt 3 ] || ([ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -lt 8 ]); then
    error "Python 3.8+ is required, but found version $PY_VERSION. Please upgrade Python."
  else
    success "Python version $PY_VERSION meets the 3.8+ requirement"
  fi
}

# Check for Terraform
check_terraform() {
  title "Checking Terraform installation"

  if ! command -v terraform &> /dev/null; then
    error "Terraform is required but not found. Please install Terraform 1.0.0 or newer."
  fi

  # Get Terraform version
  TF_VERSION=$(terraform version -json | grep -o '"version": "[^"]*' | cut -d'"' -f4)

  # Compare version to 1.0.0
  if [ "$(printf '%s\n' "1.0.0" "$TF_VERSION" | sort -V | head -n1)" != "1.0.0" ]; then
    error "Terraform 1.0.0+ is required, but found version $TF_VERSION. Please upgrade Terraform."
  else
    success "Terraform version $TF_VERSION meets the 1.0.0+ requirement"
  fi
}

# Check for Ansible
check_ansible() {
  title "Checking Ansible installation"

  if ! command -v ansible &> /dev/null; then
    warning "Ansible not found. It will be installed in the virtual environment."
    return
  fi

  # Get Ansible version
  ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2)

  # Compare version to 2.9.0
  if [ "$(printf '%s\n' "2.9.0" "$ANSIBLE_VERSION" | sort -V | head -n1)" != "2.9.0" ]; then
    warning "Ansible 2.9.0+ is recommended, but found version $ANSIBLE_VERSION. A newer version will be installed in the virtual environment."
  else
    success "Ansible version $ANSIBLE_VERSION meets the 2.9.0+ requirement"
  fi
}

# Check for Azure CLI
check_azure_cli() {
  title "Checking Azure CLI installation"

  if ! command -v az &> /dev/null; then
    warning "Azure CLI not found. Please install it if you plan to use Azure."
  else
    # Get Azure CLI version
    AZ_VERSION=$(az version --output tsv --query 'azure-cli')
    success "Azure CLI version $AZ_VERSION found"
  fi
}

# Check for OCI CLI
check_oci_cli() {
  title "Checking OCI CLI installation"

  if ! command -v oci &> /dev/null; then
    warning "OCI CLI not found. Please install it if you plan to use Oracle Cloud."
  else
    # Get OCI CLI version
    OCI_VERSION=$(oci --version)
    success "OCI CLI version $OCI_VERSION found"
  fi
}

# Check for venv module
check_venv() {
  title "Checking venv module"

  if ! $PYTHON_CMD -c "import venv" &> /dev/null; then
    warning "Python venv module not found. Attempting to install..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3-venv
      elif command -v yum &> /dev/null; then
        sudo yum install -y python3-venv
      else
        error "Unable to install python3-venv automatically. Please install it manually."
      fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      warning "On macOS, venv should be included with Python. If not, try reinstalling Python."
    else
      error "Unable to install python3-venv automatically. Please install it manually."
    fi

    # Check again
    if ! $PYTHON_CMD -c "import venv" &> /dev/null; then
      error "Python venv module installation failed. Please install it manually."
    fi
  fi

  success "Python venv module is available"
}

# Create and activate virtual environment
setup_venv() {
  VENV_NAME="${1:-venv}"
  title "Setting up virtual environment: $VENV_NAME"

  # Check if virtual environment already exists
  if [ -d "$VENV_NAME" ]; then
    warning "Virtual environment '$VENV_NAME' already exists."
    read -p "Do you want to recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      warning "Removing existing virtual environment..."
      rm -rf "$VENV_NAME"
    else
      success "Using existing virtual environment"
      return
    fi
  fi

  # Create virtual environment
  $PYTHON_CMD -m venv "$VENV_NAME" || error "Failed to create virtual environment"

  # Activate virtual environment
  source "$VENV_NAME/bin/activate" || error "Failed to activate virtual environment"

  # Upgrade pip
  pip install --upgrade pip || error "Failed to upgrade pip"

  success "Virtual environment created and activated"
}

# Install required packages
install_packages() {
  title "Installing required packages"

  # Install Ansible and related packages
  pip install ansible-core==2.17.10 ansible==10.7.0 ansible-compat==25.1.5 || error "Failed to install Ansible packages"

  # Install cloud provider CLIs
  pip install azure-cli oci-cli || warning "Failed to install cloud provider CLIs"

  # Install development tools
  pip install pre-commit flake8 ansible-lint || warning "Failed to install development tools"

  success "Required packages installed"
}

# Main setup process
main() {
  title "Starting setup process"

  check_python
  check_terraform
  check_ansible
  check_azure_cli
  check_oci_cli
  check_venv
  setup_venv
  install_packages

  title "Setup completed successfully"
  echo
  echo "To activate the virtual environment, run:"
  echo "source venv/bin/activate"
}

# Run main function
main
