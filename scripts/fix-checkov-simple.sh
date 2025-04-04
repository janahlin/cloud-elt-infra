#!/bin/bash
# A simple script to properly install checkov without dependency issues

set -e

echo "===== Simple Checkov Fix Script ====="

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

# Uninstall checkov if it's installed
echo "Uninstalling any existing checkov installations..."
pip uninstall -y checkov

# Install a known working version of checkov
echo "Installing checkov version 2.3.75 (known to be compatible)..."
pip install checkov==2.3.75

# Update requirements.txt if it exists
if [ -f "requirements.txt" ]; then
  echo "Updating requirements.txt..."
  grep -v "^checkov" requirements.txt > requirements.tmp
  echo "checkov==2.3.75" >> requirements.tmp
  mv requirements.tmp requirements.txt
  echo "✓ Updated requirements.txt"
fi

# Verify installation
echo "Verifying checkov installation..."
if checkov --version; then
  echo "✓ Checkov was installed successfully!"
else
  echo "✗ Checkov installation verification failed."
  exit 1
fi

echo "===== Checkov installation fixed! ====="
