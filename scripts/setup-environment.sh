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
    
    wget -q "${TERRAFORM_URL}" -O terraform.zip
    unzip -o terraform.zip
    chmod +x terraform
    
    # Move to local bin directory
    mkdir -p ~/.local/bin
    mv terraform ~/.local/bin/
    
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
  
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
    sudo yum install -y azure-cli
  elif [[ "$OS" == "macOS" ]]; then
    brew install azure-cli
  else
    pip install azure-cli
  fi
  
  # Verify installation
  az --version
  
  echo "Azure CLI installed successfully."
}

# Install OCI CLI
install_oci_cli() {
  echo "Installing OCI CLI..."
  
  pip install oci-cli
  
  # Verify installation
  oci --version
  
  echo "OCI CLI installed successfully."
}

# Install security scanning tools
install_security_tools() {
  echo "Installing security scanning tools..."
  
  # Install checkov
  pip install checkov
  
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
  echo "   # For Azure"
  echo "   az login"
  echo
  echo "   # For OCI"
  echo "   oci setup config"
  echo
  echo "3. Deploy infrastructure using Ansible playbooks"
  echo "=============================="
}

# Run the main function
main 