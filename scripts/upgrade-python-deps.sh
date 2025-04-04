#!/bin/bash
# Script to upgrade Python dependencies and resolve dependency conflicts

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

# Check if running in virtual environment
check_venv() {
  title "Checking virtual environment"

  if [ -z "$VIRTUAL_ENV" ]; then
    warning "Not running in a Python virtual environment."
    warning "It's strongly recommended to perform dependency upgrades in a virtual environment."
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

# Backup requirements file
backup_requirements() {
  title "Backing up requirements file"

  if [ -f "requirements.txt" ]; then
    BACKUP_FILE="requirements.txt.backup-$(date +%Y%m%d-%H%M%S)"
    cp requirements.txt "$BACKUP_FILE"
    success "Backed up requirements.txt to $BACKUP_FILE"
  else
    error "requirements.txt not found in the current directory"
  fi
}

# Resolve common dependency conflicts
resolve_conflicts() {
  title "Resolving known dependency conflicts"

  echo "Adjusting requirements.txt to fix common conflicts..."

  # Fix click version conflict (needed for black and ansible packages)
  if grep -q "click==" requirements.txt; then
    sed -i 's/click==8.1.8/click==8.0.4/g' requirements.txt
    success "Fixed click version to 8.0.4"
  else
    echo "click==8.0.4" >> requirements.txt
    success "Added click==8.0.4 to requirements.txt"
  fi

  # Remove strict version pinning for tools that cause conflicts
  sed -i '/^black==/d' requirements.txt
  sed -i '/^checkov==/d' requirements.txt

  echo "# Tools with relaxed version requirements (to avoid conflicts)" >> requirements.txt
  echo "black>=22.0.0" >> requirements.txt
  echo "checkov>=2.0.0" >> requirements.txt

  success "Removed strict version pinning for black and checkov"
}

# Install dependencies with pip
install_deps() {
  title "Installing dependencies"

  echo "Installing dependencies with pip..."
  pip install -r requirements.txt

  success "Dependencies installed successfully"
}

# Check for conflicts
check_conflicts() {
  title "Checking for remaining conflicts"

  echo "Running pip check to detect dependency conflicts..."
  if pip check; then
    success "No dependency conflicts detected!"
  else
    warning "Some dependency conflicts still exist."
    warning "You may need to manually adjust requirements.txt or create a constraints.txt file."
    warning "Consider using 'pip-compile' from the pip-tools package to generate a compatible requirements file."
  fi
}

# Main function
main() {
  # Check if running in virtual environment
  check_venv

  # Backup requirements file
  backup_requirements

  # Resolve known conflicts
  resolve_conflicts

  # Install dependencies
  install_deps

  # Check for conflicts
  check_conflicts

  echo ""
  title "Python Dependencies Update Complete"
  success "Python dependencies have been updated with conflict resolution!"
  echo ""
  echo "If you encounter any issues, you can restore the backup:"
  echo "  cp $BACKUP_FILE requirements.txt"
  echo ""
  echo "For more advanced dependency management, consider using pip-tools:"
  echo "  pip install pip-tools"
  echo "  pip-compile --output-file=requirements.txt pyproject.toml"
}

# Run main function
main
