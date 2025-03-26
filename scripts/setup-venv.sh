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
      warning "Using existing virtual environment."
      return
    fi
  fi
  
  # Create virtual environment
  echo "Creating virtual environment..."
  $PYTHON_CMD -m venv "$VENV_NAME"
  success "Virtual environment created successfully"
  
  # Determine activation script based on OS
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT="$VENV_NAME/Scripts/activate"
  else
    ACTIVATE_SCRIPT="$VENV_NAME/bin/activate"
  fi
  
  # Activate virtual environment
  echo "Activating virtual environment..."
  source "$ACTIVATE_SCRIPT"
  
  # Upgrade pip
  echo "Upgrading pip..."
  $PYTHON_CMD -m pip install --upgrade pip
}

# Install requirements
install_requirements() {
  title "Installing dependencies"
  
  if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    # Installing requirements in smaller groups to avoid failures
    # Core automation requirements
    pip install "ansible>=2.9.0,<3.0.0" "python-terraform>=0.10.1" "jinja2>=3.0.0" "pyyaml>=6.0.0" "pre-commit>=2.20.0"
    # Azure dependencies
    pip install "azure-cli>=2.36.0" "azure-mgmt-resource>=21.0.0" "azure-mgmt-compute>=25.0.0" "azure-mgmt-network>=20.0.0" "azure-mgmt-storage>=19.0.0" "azure-mgmt-databricks>=1.0.0" "azure-mgmt-datafactory>=2.0.0" "azure-mgmt-recoveryservices>=2.0.0" "azure-mgmt-recoveryservicesbackup>=5.0.0" "pywinrm>=0.4.0"
    # OCI and other cloud dependencies
    pip install "oci-cli>=3.10.0" "oci>=2.70.0" "boto3>=1.24.0"
    # Security and linting tools
    pip install "checkov>=2.0.0" "ansible-lint>=6.0.0,<7.0.0" "pylint>=2.12.0" "yamllint>=1.26.0"
    
    success "Dependencies installed successfully"
  else
    warning "requirements.txt not found. Creating a basic one..."
    cat > requirements.txt << EOF
ansible>=2.9.0,<3.0.0
python-terraform>=0.10.1
checkov>=2.0.0
pre-commit>=2.20.0
jinja2>=3.0.0
pyyaml>=6.0.0
EOF
    
    pip install -r requirements.txt
    success "Basic dependencies created and installed"
  fi
}

# Main function
main() {
  title "Python Virtual Environment Setup"
  
  # Check Python installation
  check_python
  
  # Check venv module
  check_venv
  
  # Get virtual environment name
  VENV_NAME="venv"
  if [ "$1" != "" ]; then
    VENV_NAME="$1"
  fi
  
  # Setup virtual environment
  setup_venv "$VENV_NAME"
  
  # Install requirements
  install_requirements
  
  # Print activation instructions
  echo ""
  title "Virtual Environment Setup Complete"
  echo ""
  echo "Your virtual environment '${VENV_NAME}' has been created and dependencies installed."
  echo ""
  echo "To activate the virtual environment, run:"
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "  ${VENV_NAME}\\Scripts\\activate"
  else
    echo "  source ${VENV_NAME}/bin/activate"
  fi
  echo ""
  echo "To deactivate the virtual environment when you're done, run:"
  echo "  deactivate"
  echo ""
  echo "Your virtual environment is currently active in this terminal session."
  echo ""
}

# Run main function with the first argument as virtual environment name
main "$1" 