#!/bin/bash
# Script to fix Ansible collection conflicts by using virtual environment specific collections

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

# Check if script is run in the project root
check_project_root() {
  if [ ! -d "venv" ] || [ ! -d "ansible" ]; then
    error "This script must be run from the project root directory"
  fi
}

# Fix Ansible collection conflicts
fix_collections() {
  title "Fixing Ansible Collection Conflicts"

  # Determine Python version in virtual environment
  PYTHON_VERSION=$(venv/bin/python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  COLLECTIONS_PATH="venv/lib/python$PYTHON_VERSION/site-packages/ansible_collections"

  # Check if the virtual environment is active
  if [ -z "$VIRTUAL_ENV" ]; then
    warning "Virtual environment is not active. Activating..."
    source venv/bin/activate
  else
    success "Using active virtual environment: $VIRTUAL_ENV"
  fi

  # Create collections directory if it doesn't exist
  mkdir -p "$COLLECTIONS_PATH"

  # Check for existing collections in the virtual environment
  echo "Checking for existing collections in virtual environment..."
  if [ -d "$COLLECTIONS_PATH/ansible" ] || [ -d "$COLLECTIONS_PATH/community" ]; then
    warning "Existing collections found in virtual environment"
    read -p "Do you want to clean and reinstall them? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Removing existing collections..."
      rm -rf "$COLLECTIONS_PATH/ansible"
      rm -rf "$COLLECTIONS_PATH/community"
    else
      warning "Skipping collection cleanup"
    fi
  fi

  # Install collections to virtual environment
  echo "Installing collections to virtual environment..."
  ansible-galaxy collection install ansible.posix:1.5.4 -p "$COLLECTIONS_PATH" -f
  ansible-galaxy collection install community.general:9.1.0 -p "$COLLECTIONS_PATH" -f

  # Check ansible.cfg for collections path
  if grep -q "collections_paths" ansible/ansible.cfg; then
    echo "Updating collections_paths in ansible.cfg..."
    sed -i "s|collections_paths.*|collections_paths = ./venv/lib/python$PYTHON_VERSION/site-packages/ansible_collections:~/.ansible/collections|" ansible/ansible.cfg
  else
    echo "Adding collections_paths to ansible.cfg..."
    sed -i "/\[defaults\]/a collections_paths = ./venv/lib/python$PYTHON_VERSION/site-packages/ansible_collections:~/.ansible/collections" ansible/ansible.cfg
  fi

  success "Collections installed in virtual environment and ansible.cfg updated"
  success "This project will now use the collections from the virtual environment first"
}

# Main function
main() {
  check_project_root
  fix_collections

  echo ""
  title "Collection Fix Complete"
  echo ""
  echo "Your Ansible collections have been installed in the virtual environment."
  echo "The specific versions installed are:"
  echo "  ansible.posix: 1.5.4"
  echo "  community.general: 9.1.0"
  echo ""
  echo "The ansible.cfg has been updated to use these collections first."
  echo "This should resolve the collection conflict warnings."
  echo ""
}

# Run main function
main
