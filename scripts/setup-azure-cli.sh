#!/bin/bash
# Setup script for Azure CLI in a dedicated virtual environment

set -e

echo "==== Setting up Azure CLI in dedicated environment ===="

# Create virtual environment for Azure CLI
python3 -m venv cloud_venvs/azure

# Activate the environment
source cloud_venvs/azure/bin/activate

# Install Azure CLI requirements
pip install -r azure-requirements.txt

echo "✓ Azure CLI setup complete"
echo ""
echo "To use Azure CLI, activate this environment:"
echo "  source cloud_venvs/azure/bin/activate"
echo ""
echo "Then use 'az' commands as normal"
