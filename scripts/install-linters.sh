#!/bin/bash
# Script to install all linters for cloud-elt-infra project

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

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
elif [ "$(uname)" == "Darwin" ]; then
  OS="macOS"
else
  OS="Unknown"
fi

title "Installing linters for your cloud-elt-infra project"
echo "Detected OS: $OS"

# Check if running in virtual environment
check_venv() {
  title "Checking virtual environment"
  
  if [ -z "$VIRTUAL_ENV" ]; then
    warning "Not running in a Python virtual environment."
    warning "It's strongly recommended to install Python linters in a virtual environment."
    warning "To create and activate a virtual environment run:"
    warning "  ./scripts/setup-venv.sh"
    warning "  source venv/bin/activate  # Linux/macOS"
    warning "  venv\\Scripts\\activate     # Windows"
    
    read -p "Continue without a virtual environment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting. Please create a virtual environment and try again."
      exit 1
    fi
  else
    success "Running in virtual environment: $VIRTUAL_ENV"
  fi
}

# Install TFLint
install_tflint() {
  title "Installing TFLint (Terraform Linter)"
  
  if command -v tflint &> /dev/null; then
    warning "TFLint is already installed, skipping installation."
    return
  fi
  
  if [[ "$OS" == "macOS" ]]; then
    echo "Installing TFLint using Homebrew..."
    brew install tflint
  else
    echo "Installing TFLint using the official installer..."
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
  fi
  
  if command -v tflint &> /dev/null; then
    success "TFLint installed successfully. Version: $(tflint --version)"
  else
    error "Failed to install TFLint."
  fi
}

# Install ansible-lint
install_ansible_lint() {
  title "Installing ansible-lint (Ansible Linter)"
  
  if command -v ansible-lint &> /dev/null; then
    warning "ansible-lint is already installed, skipping installation."
    return
  fi
  
  echo "Installing ansible-lint using pip..."
  pip install "ansible-lint>=6.0.0,<7.0.0"
  
  if command -v ansible-lint &> /dev/null; then
    success "ansible-lint installed successfully. Version: $(ansible-lint --version | head -n 1)"
  else
    error "Failed to install ansible-lint."
  fi
}

# Install pylint
install_pylint() {
  title "Installing pylint (Python Linter)"
  
  if command -v pylint &> /dev/null; then
    warning "pylint is already installed, skipping installation."
    return
  fi
  
  echo "Installing pylint using pip..."
  pip install "pylint>=2.12.0"
  
  if command -v pylint &> /dev/null; then
    success "pylint installed successfully. Version: $(pylint --version | head -n 1)"
  else
    error "Failed to install pylint."
  fi
}

# Install shellcheck
install_shellcheck() {
  title "Installing shellcheck (Shell Script Linter)"
  
  if command -v shellcheck &> /dev/null; then
    warning "shellcheck is already installed, skipping installation."
    return
  fi
  
  if [[ "$OS" == "macOS" ]]; then
    echo "Installing shellcheck using Homebrew..."
    brew install shellcheck
  elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    echo "Installing shellcheck using apt..."
    sudo apt-get update
    sudo apt-get install -y shellcheck
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    echo "Installing shellcheck using yum..."
    sudo yum install -y epel-release
    sudo yum install -y ShellCheck
  else
    warning "Automatic installation not supported for your OS. Please install shellcheck manually."
    warning "Visit: https://github.com/koalaman/shellcheck#installing"
    return
  fi
  
  if command -v shellcheck &> /dev/null; then
    success "shellcheck installed successfully. Version: $(shellcheck --version | grep version)"
  else
    error "Failed to install shellcheck."
  fi
}

# Install yamllint
install_yamllint() {
  title "Installing yamllint (YAML Linter)"
  
  if command -v yamllint &> /dev/null; then
    warning "yamllint is already installed, skipping installation."
    return
  fi
  
  echo "Installing yamllint using pip..."
  pip install "yamllint>=1.26.0"
  
  if command -v yamllint &> /dev/null; then
    success "yamllint installed successfully. Version: $(yamllint --version)"
  else
    error "Failed to install yamllint."
  fi
}

# Main function
main() {
  # Check if running in virtual environment
  check_venv
  
  install_tflint
  install_ansible_lint
  install_pylint
  install_shellcheck
  install_yamllint
  
  echo ""
  title "Installation Complete"
  success "All linters have been installed successfully!"
  echo ""
  echo "You can now run the linters using:"
  echo "  ./scripts/run-linters.sh"
  
  if [ -n "$VIRTUAL_ENV" ]; then
    echo ""
    echo "Note: These linters are installed in your current virtual environment."
    echo "Make sure to activate this environment when running the linters:"
    echo "  source $(basename $VIRTUAL_ENV)/bin/activate  # Linux/macOS"
    echo "  $(basename $VIRTUAL_ENV)\\Scripts\\activate     # Windows"
  fi
}

# Run main function
main 