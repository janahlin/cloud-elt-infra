#!/bin/bash
# Script to fix checkov dependencies

set -e

echo "===== Fixing Checkov Dependencies ====="

# Check if in virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
  echo "Warning: Not running in a virtual environment."
  echo "It's recommended to run this script inside a virtual environment."
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting."
    exit 1
  fi
else
  echo "✓ Running in virtual environment: $VIRTUAL_ENV"
fi

# Uninstall any existing checkov and related dependencies
echo "Removing any existing conflicting packages..."
pip uninstall -y checkov bc-python-hcl2 bc-detect-secrets bc-jsonpath-ng dpath

# Install compatible versions in the correct order
echo "Installing bc-* dependencies with compatible versions..."
pip install "dpath>=1.5.0,<2.0.0" bc-python-hcl2==0.3.51 bc-detect-secrets==1.4.13 bc-jsonpath-ng==1.5.9

echo "Installing checkov..."
pip install checkov==2.3.75

# Update requirements.txt if it exists
if [ -f "requirements.txt" ]; then
  echo "Updating requirements.txt..."
  # Create a backup with timestamp in the content
  echo "# Backup created on $(date)" > requirements.txt.backup
  cat requirements.txt >> requirements.txt.backup

  # Remove checkov and bc-* dependencies from requirements.txt
  grep -v "^checkov\|^bc-" requirements.txt > requirements.tmp

  # Add compatible versions
  echo "# Pin checkov and its dependencies to compatible versions" >> requirements.tmp
  echo "dpath==1.5.0" >> requirements.tmp
  echo "checkov==2.3.75" >> requirements.tmp
  echo "bc-python-hcl2==0.3.51" >> requirements.tmp
  echo "bc-detect-secrets==1.4.13" >> requirements.tmp
  echo "bc-jsonpath-ng==1.5.9" >> requirements.tmp

  # Replace requirements.txt
  mv requirements.tmp requirements.txt

  echo "✓ Updated requirements.txt with compatible dependency versions"
fi

# Cleanup any temporary files that might be left
rm -f requirements.tmp

# Verify installation
echo "Verifying checkov installation..."
if checkov --version; then
  echo "✓ Checkov and its dependencies were installed successfully!"
else
  echo "✗ Checkov installation verification failed."
  exit 1
fi

echo "===== Checkov Dependencies Fixed! ====="
