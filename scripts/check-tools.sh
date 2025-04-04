#!/bin/bash
# Check if all required tools are installed and their versions

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
}

warning() {
  echo -e "${WARNING_COLOR}! $1${RESET_COLOR}"
}

check_command() {
  local cmd=$1
  local min_version=$2
  local cmd_path=$(which $cmd 2>/dev/null || echo "")

  if [ -z "$cmd_path" ]; then
    error "$cmd not found"
    return 1
  fi

  local version=$($cmd --version 2>&1 | head -n 1 | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" | head -n 1)

  if [ -z "$version" ]; then
    version=$($cmd --version 2>&1 | head -n 1)
    success "$cmd found, version: $version"
    return 0
  fi

  if [ -n "$min_version" ]; then
    if [[ $(printf '%s\n' "$min_version" "$version" | sort -V | head -n1) == "$min_version" ]]; then
      success "$cmd found, version: $version (required: $min_version)"
    else
      warning "$cmd found, but version $version is older than required $min_version"
    fi
  else
    success "$cmd found, version: $version"
  fi
}

check_python_package() {
  local package=$1
  local min_version=$2

  if pip show "$package" &>/dev/null; then
    local version=$(pip show "$package" | grep "Version:" | awk '{print $2}')

    if [ -n "$min_version" ]; then
      if [[ $(printf '%s\n' "$min_version" "$version" | sort -V | head -n1) == "$min_version" ]]; then
        success "Python package $package found, version: $version (required: $min_version)"
      else
        warning "Python package $package found, but version $version is older than required $min_version"
      fi
    else
      success "Python package $package found, version: $version"
    fi
  else
    error "Python package $package not found"
    return 1
  fi
}

# Check basic commands
title "Checking basic commands"
check_command git "2.0.0"
check_command python "3.8.0" || check_command python3 "3.8.0"
check_command pip "20.0.0" || check_command pip3 "20.0.0"

# Check infrastructure tools
title "Checking infrastructure tools"
check_command terraform "1.0.0"
check_command ansible "2.9.0"

# Check cloud provider CLIs
title "Checking cloud provider CLIs"
check_command az || warning "Azure CLI not found (required only for Azure deployments)"
check_command oci || warning "OCI CLI not found (required only for OCI deployments)"

# Check security tools
title "Checking security tools"
check_command checkov || warning "checkov not found (required for security scanning)"
check_command tfsec || warning "tfsec not found (required for security scanning)"

# Check Python packages
title "Checking Python packages"
check_python_package ansible "2.9.0"
check_python_package "pre-commit" || warning "pre-commit not found (required for development)"

# Check if running in virtual environment
title "Environment check"
if [[ -n "$VIRTUAL_ENV" ]]; then
  success "Running in Python virtual environment: $VIRTUAL_ENV"
else
  warning "Not running in a Python virtual environment. It's recommended to use a virtual environment."
fi

# Final summary
title "Summary"
echo
echo "If any tools are missing or outdated, run the setup script:"
echo "  ./scripts/setup-environment.sh"
echo
echo "Or follow the manual installation instructions in docs/installation.md"
