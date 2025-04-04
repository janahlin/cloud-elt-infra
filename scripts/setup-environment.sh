#!/bin/bash
# Setup script for cloud-elt-infra project
# Installs all required tools and dependencies

set -e

echo "===== Cloud ELT Infrastructure - Environment Setup ====="
echo "This script will install all required tools for the project"
echo "====================================================="

# Check if script is run with sudo/root and warn if it is
if [ "$(id -u)" -eq 0 ]; then
  echo "WARNING: Running as root is not recommended. Some tools work better when installed as a regular user."
  echo "Consider running without sudo."
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
elif [ "$(uname)" == "Darwin" ]; then
  OS="macOS"
else
  OS="Unknown"
fi

echo "Detected OS: $OS"

# Install system dependencies based on OS
install_system_deps() {
  echo "Installing system dependencies..."

  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv git curl wget unzip jq
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    sudo yum update -y
    sudo yum install -y python3 python3-pip git curl wget unzip jq
  elif [[ "$OS" == "macOS" ]]; then
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew update
    brew install python@3 git wget jq
  else
    echo "Unsupported OS. Please install dependencies manually: Python 3.8+, git, etc."
    return 1
  fi

  return 0
}

# Install Python and set up virtual environment
setup_python() {
  echo "Setting up Python environment..."

  # Create virtual environment
  python3 -m venv venv

  # Activate virtual environment
  source venv/bin/activate

  # Upgrade pip
  python -m pip install --upgrade pip

  # Install Python dependencies
  if [ -f requirements.txt ]; then
    pip install -r requirements.txt
  else
    echo "requirements.txt not found, creating a basic one..."
    echo "ansible>=2.9,<3.0" > requirements.txt
    echo "checkov" >> requirements.txt
    echo "tfsec" >> requirements.txt
    pip install -r requirements.txt
  fi

  echo "Python environment set up successfully."
}

# Install Ansible
install_ansible() {
  echo "Installing Ansible..."
  pip install "ansible>=2.9,<3.0"

  # Verify installation
  ansible --version

  echo "Ansible installed successfully."
}

# Install Terraform
install_terraform() {
  echo "Installing Terraform..."

  TERRAFORM_VERSION="1.0.0"

  if [[ "$OS" == "macOS" ]]; then
    brew install terraform
  else
    # Download and install Terraform
    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_$(uname -s | tr '[:upper:]' '[:lower:]')_amd64.zip"

    # Use a temporary directory to avoid conflicts with terraform code directory
    TEMP_DIR="terraform_tmp_install"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    wget -q "${TERRAFORM_URL}" -O terraform.zip

    # Check if terraform binary exists in the temp directory and remove it
    if [ -f "terraform" ]; then
      echo "Removing existing terraform binary..."
      rm -f terraform
    fi

    unzip -o terraform.zip
    chmod +x terraform

    # Move to local bin directory
    mkdir -p ~/.local/bin
    mv terraform ~/.local/bin/

    # Clean up the temp directory
    cd ..
    rm -rf "$TEMP_DIR"

    # Add to PATH if not already in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
      source ~/.bashrc
    fi
  fi

  # Verify installation
  terraform version

  echo "Terraform installed successfully."
}

# Install Azure CLI
install_azure_cli() {
  echo "Installing Azure CLI..."

  # Create dedicated virtual environment for Azure CLI
  if [ ! -d "cloud_venvs/azure" ]; then
    echo "Creating dedicated environment for Azure CLI..."
    mkdir -p cloud_venvs/azure
    python3 -m venv cloud_venvs/azure

    # Check if azure-requirements.txt exists
    if [ ! -f "azure-requirements.txt" ]; then
      echo "Creating azure-requirements.txt..."
      grep -v "^oci" requirements.txt.full > azure-requirements.txt
      # Ensure jmespath is properly pinned for Azure
      sed -i '/^jmespath/d' azure-requirements.txt
      echo "jmespath>=0.7.1,<2.0.0" >> azure-requirements.txt
    fi

    # Install Azure CLI in the dedicated environment
    echo "Installing Azure CLI in dedicated environment..."
    cloud_venvs/azure/bin/pip install -r azure-requirements.txt
  fi

  # Create a wrapper script if it doesn't exist
  if [ ! -f "scripts/az" ]; then
    echo "Creating Azure CLI wrapper script..."
    cat > scripts/az << 'EOF'
#!/bin/bash
# Wrapper script for Azure CLI

AZURE_VENV="$PWD/cloud_venvs/azure"

if [ ! -d "$AZURE_VENV" ]; then
  echo "Azure CLI environment not found. Setting it up now..."
  ./scripts/setup-azure-cli.sh
fi

# Run Azure CLI from the dedicated environment
"$AZURE_VENV/bin/az" "$@"
EOF
    chmod +x scripts/az
  fi

  echo "Azure CLI installed successfully."
  echo "Use './scripts/az' to run Azure CLI commands."
}

# Install OCI CLI
install_oci_cli() {
  echo "Installing OCI CLI..."

  # Create dedicated virtual environment for OCI CLI
  if [ ! -d "cloud_venvs/oci" ]; then
    echo "Creating dedicated environment for OCI CLI..."
    mkdir -p cloud_venvs/oci
    python3 -m venv cloud_venvs/oci

    # Check if oci-requirements.txt exists
    if [ ! -f "oci-requirements.txt" ]; then
      echo "Creating oci-requirements.txt..."
      grep -v "^azure" requirements.txt.full > oci-requirements.txt
      # Pin jmespath for OCI
      sed -i '/^jmespath/d' oci-requirements.txt
      echo "jmespath==0.10.0" >> oci-requirements.txt
    fi

    # Install OCI CLI in the dedicated environment
    echo "Installing OCI CLI in dedicated environment..."
    cloud_venvs/oci/bin/pip install -r oci-requirements.txt
  fi

  # Create a wrapper script if it doesn't exist
  if [ ! -f "scripts/oci" ]; then
    echo "Creating OCI CLI wrapper script..."
    cat > scripts/oci << 'EOF'
#!/bin/bash
# Wrapper script for OCI CLI

OCI_VENV="$PWD/cloud_venvs/oci"

if [ ! -d "$OCI_VENV" ]; then
  echo "OCI CLI environment not found. Setting it up now..."
  ./scripts/setup-oci-cli.sh
fi

# Run OCI CLI from the dedicated environment
"$OCI_VENV/bin/oci" "$@"
EOF
    chmod +x scripts/oci
  fi

  echo "OCI CLI installed successfully."
  echo "Use './scripts/oci' to run OCI CLI commands."
}

# Install security scanning tools
install_security_tools() {
  echo "Installing security scanning tools..."

  # Install checkov with a specific version
  echo "Installing checkov..."
  pip install "checkov==2.3.75"

  # Install tfsec
  if [[ "$OS" == "macOS" ]]; then
    brew install tfsec
  else
    # Install tfsec using curl
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
  fi

  # Verify installations
  echo "Verifying security tools installations:"
  checkov --version
  tfsec --version

  echo "Security scanning tools installed successfully."
}

# Setup pre-commit hooks
setup_pre_commit() {
  echo "Setting up pre-commit hooks..."

  pip install pre-commit

  if [ -f .pre-commit-config.yaml ]; then
    pre-commit install
    echo "Pre-commit hooks installed successfully."
  else
    echo "Warning: .pre-commit-config.yaml not found. Skipping pre-commit setup."
  fi
}

# Main installation process
main() {
  install_system_deps

  # Ensure we have a full copy of requirements.txt
  if [ ! -f "requirements.txt.full" ] && [ -f "requirements.txt" ]; then
    cp requirements.txt requirements.txt.full
  fi

  # Check if we need to split requirements
  if [ -f "requirements.txt.full" ] && ! [ -f "azure-requirements.txt" ] && ! [ -f "oci-requirements.txt" ]; then
    echo "Creating separate requirements files for cloud CLIs to avoid conflicts..."

    # Create a minimal main requirements.txt without cloud CLIs
    grep -v "^azure\|^oci\|^jmespath" requirements.txt.full > requirements.txt
    echo "# Core dependencies without cloud CLIs" >> requirements.txt
    echo "click==8.0.4" >> requirements.txt
    echo "ansible>=2.9.0,<3.0.0" >> requirements.txt
    echo "python-terraform>=0.10.1" >> requirements.txt
    echo "checkov>=2.0.0" >> requirements.txt
    echo "black>=22.0.0" >> requirements.txt
    echo "jinja2>=3.0.0" >> requirements.txt
    echo "pyyaml>=6.0.0" >> requirements.txt
    echo "pre-commit>=2.20.0" >> requirements.txt
  fi

  setup_python
  install_ansible
  install_terraform

  # Ask which cloud providers to set up
  echo
  echo "Which cloud provider(s) would you like to set up? (You can select both)"
  read -p "Azure (y/n)? " -n 1 -r azure_choice
  echo
  read -p "OCI (y/n)? " -n 1 -r oci_choice
  echo

  if [[ $azure_choice =~ ^[Yy]$ ]]; then
    install_azure_cli
  fi

  if [[ $oci_choice =~ ^[Yy]$ ]]; then
    install_oci_cli
  fi

  install_security_tools
  setup_pre_commit

  echo
  echo "===== Installation Complete ====="
  echo "All required tools for Cloud ELT Infrastructure have been installed!"
  echo
  echo "Next steps:"
  echo "1. Create configuration files:"
  echo "   cp example.azure-vars.yml azure-vars.yml  # For Azure deployments"
  echo "   cp example.oci-vars.yml oci-vars.yml      # For OCI deployments"
  echo
  echo "2. Configure cloud provider credentials:"
  if [[ $azure_choice =~ ^[Yy]$ ]]; then
    echo "   # For Azure"
    echo "   ./scripts/az login"
  fi
  if [[ $oci_choice =~ ^[Yy]$ ]]; then
    echo "   # For OCI"
    echo "   ./scripts/oci setup config"
  fi
  echo
  echo "3. Deploy infrastructure using Ansible playbooks"
  echo "=============================="
}

# Run the main function
main
