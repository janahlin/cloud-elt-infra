#!/bin/bash
# Setup script for OCI CLI in a dedicated virtual environment

set -e

echo "==== Setting up OCI CLI in dedicated environment ===="

# Create virtual environment for OCI CLI
python3 -m venv cloud_venvs/oci

# Activate the environment
source cloud_venvs/oci/bin/activate

# Install OCI CLI requirements
pip install -r oci-requirements.txt

echo "✓ OCI CLI setup complete"
echo ""
echo "To use OCI CLI, activate this environment:"
echo "  source cloud_venvs/oci/bin/activate"
echo ""
echo "Then use 'oci' commands as normal"
