#!/bin/bash
# Script to fix expired GPG keys for various repositories
# This helps resolve "The following signatures couldn't be verified because the public key is not available" errors

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

# Run as root check
if [ "$EUID" -ne 0 ]; then
  warning "This script needs to be run as root to update GPG keys."
  warning "Please run with sudo:"
  warning "  sudo ./scripts/fix-gpg-keys.sh"
  exit 1
fi

title "Fixing expired GPG keys for repositories"

# Fix GitHub CLI GPG key
fix_github_cli_key() {
  title "Updating GitHub CLI GPG key"

  echo "Creating keyrings directory if it doesn't exist..."
  sudo mkdir -p /usr/share/keyrings

  echo "Fetching the latest GitHub CLI GPG key..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

  echo "Setting up GitHub CLI repository with the new key..."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  success "GitHub CLI GPG key updated successfully"
}

# Fix Kubernetes GPG key
fix_kubernetes_key() {
  title "Updating Kubernetes GPG key"

  echo "Removing old Kubernetes GPG key if it exists..."
  sudo rm -f /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
  sudo rm -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg

  echo "Creating keyrings directory if it doesn't exist..."
  sudo mkdir -p /etc/apt/keyrings

  echo "Fetching the latest Kubernetes GPG key..."
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

  echo "Setting up Kubernetes repository with the new key..."
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

  success "Kubernetes GPG key updated successfully"
}

# Fix HashiCorp GPG key
fix_hashicorp_key() {
  title "Updating HashiCorp GPG key (for Terraform)"

  echo "Removing old HashiCorp GPG key if it exists..."
  sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg

  echo "Fetching the latest HashiCorp GPG key..."
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

  echo "Setting up HashiCorp repository with the new key..."
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

  success "HashiCorp GPG key updated successfully"
}

# Fix Microsoft GPG key (for Azure CLI)
fix_microsoft_key() {
  title "Updating Microsoft GPG key (for Azure CLI)"

  echo "Removing old Microsoft GPG key if it exists..."
  sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg

  echo "Fetching the latest Microsoft GPG key..."
  curl -sL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/microsoft.gpg

  echo "Setting up Microsoft repository with the new key..."
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null

  success "Microsoft GPG key updated successfully"
}

# Update package lists
update_packages() {
  title "Updating package lists"

  echo "Running apt update to refresh package lists..."
  apt-get update

  success "Package lists updated successfully"
}

# Main function
main() {
  # Ensure apt keyrings directory exists
  mkdir -p /etc/apt/keyrings

  # Fix all repository keys
  fix_github_cli_key
  fix_kubernetes_key
  fix_hashicorp_key
  fix_microsoft_key

  # Update package lists with new keys
  update_packages

  echo ""
  title "GPG Key Update Complete"
  success "All repository GPG keys have been updated successfully!"
  echo ""
  echo "You should now be able to run apt-get update and install packages without GPG errors."
  echo "If you continue to experience issues, please try running the specific key fix functions individually."
}

# Run main function
main
