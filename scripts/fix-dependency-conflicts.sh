#!/bin/bash
# Script to fix specific dependency conflicts for cloud-elt-infra project

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
    warning "It's strongly recommended to perform dependency fixes in a virtual environment."
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

  # Use a single backup file instead of timestamped ones
  local BACKUP_FILE="requirements.txt.backup"

  # Create a backup with the current timestamp in the file content
  echo "# Backup created on $(date)" > "$BACKUP_FILE"
  cat requirements.txt >> "$BACKUP_FILE"

  success "Backed up requirements.txt to $BACKUP_FILE"
}

# Fix the dependency conflicts
fix_jmespath_conflict() {
  title "Fixing jmespath dependency conflict"

  # Create a separate directory for each cloud CLI
  mkdir -p cloud_venvs/{azure,oci}

  echo "Creating separate requirements files for cloud CLIs..."

  # Create azure-requirements.txt
  grep -v "^oci" requirements.txt > azure-requirements.txt
  # Ensure jmespath is properly pinned for Azure
  sed -i '/^jmespath/d' azure-requirements.txt
  echo "jmespath>=0.7.1,<2.0.0" >> azure-requirements.txt

  # Create oci-requirements.txt
  grep -v "^azure" requirements.txt > oci-requirements.txt
  # Pin jmespath for OCI
  sed -i '/^jmespath/d' oci-requirements.txt
  echo "jmespath==0.10.0" >> oci-requirements.txt

  # Create a minimal main requirements.txt without cloud CLIs
  grep -v "^azure\|^oci\|^jmespath\|^checkov\|^bc-\|^dpath\|^cyclonedx-python-lib\|^pycep-parser" requirements.txt > new-requirements.txt
  echo "# Core dependencies without cloud CLIs" >> new-requirements.txt
  echo "click==8.0.4" >> new-requirements.txt
  echo "ansible==10.7.0" >> new-requirements.txt
  echo "python-terraform>=0.10.1" >> new-requirements.txt
  echo "# Pin checkov and its required bc-* dependencies to compatible versions" >> new-requirements.txt
  echo "dpath==1.5.0" >> new-requirements.txt
  echo "cyclonedx-python-lib==3.1.5" >> new-requirements.txt
  echo "pycep-parser==0.3.9" >> new-requirements.txt
  echo "checkov==2.3.75" >> new-requirements.txt
  echo "bc-python-hcl2==0.3.51" >> new-requirements.txt
  echo "bc-detect-secrets==1.4.13" >> new-requirements.txt
  echo "bc-jsonpath-ng==1.5.9" >> new-requirements.txt
  echo "black>=22.0.0" >> new-requirements.txt
  echo "jinja2>=3.0.0" >> new-requirements.txt
  echo "pyyaml>=6.0.0" >> new-requirements.txt
  echo "pre-commit>=2.20.0" >> new-requirements.txt

  # Move original requirements.txt aside
  mv requirements.txt requirements.txt.full
  # Use the new minimal requirements
  mv new-requirements.txt requirements.txt

  success "Created separate requirements files for Azure CLI and OCI CLI"
  success "Updated main requirements.txt to avoid conflicts"
}

# Create Azure CLI virtual environment setup script
create_azure_cli_setup() {
  title "Creating Azure CLI setup script"

  cat > scripts/setup-azure-cli.sh << 'EOF'
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
EOF

  chmod +x scripts/setup-azure-cli.sh
  success "Created Azure CLI setup script: scripts/setup-azure-cli.sh"
}

# Create OCI CLI virtual environment setup script
create_oci_cli_setup() {
  title "Creating OCI CLI setup script"

  cat > scripts/setup-oci-cli.sh << 'EOF'
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
EOF

  chmod +x scripts/setup-oci-cli.sh
  success "Created OCI CLI setup script: scripts/setup-oci-cli.sh"
}

# Create a wrapper script for Azure CLI
create_azure_wrapper() {
  title "Creating Azure CLI wrapper script"

  cat > scripts/az << 'EOF'
#!/bin/bash
# Wrapper script for Azure CLI

AZURE_VENV="$PWD/cloud_venvs/azure"

if [ ! -d "$AZURE_VENV" ]; then
  echo "Azure CLI environment not found. Setting it up now..."
  ./scripts/setup-azure-cli.sh
fi

# Run Azure CLI from the dedicated environment
"$AZURE_VENV/bin/az" "$@"
EOF

  chmod +x scripts/az
  success "Created Azure CLI wrapper: scripts/az"
}

# Create a wrapper script for OCI CLI
create_oci_wrapper() {
  title "Creating OCI CLI wrapper script"

  cat > scripts/oci << 'EOF'
#!/bin/bash
# Wrapper script for OCI CLI

OCI_VENV="$PWD/cloud_venvs/oci"

if [ ! -d "$OCI_VENV" ]; then
  echo "OCI CLI environment not found. Setting it up now..."
  ./scripts/setup-oci-cli.sh
fi

# Run OCI CLI from the dedicated environment
"$OCI_VENV/bin/oci" "$@"
EOF

  chmod +x scripts/oci
  success "Created OCI CLI wrapper: scripts/oci"
}

# Install core dependencies
install_core_deps() {
  title "Installing core dependencies"

  echo "Installing core dependencies with pip..."

  # Remove any conflicting packages first
  echo "Removing any conflicting packages..."
  pip uninstall -y checkov bc-python-hcl2 bc-detect-secrets bc-jsonpath-ng dpath cyclonedx-python-lib pycep-parser

  # Install the new requirements
  pip install -r requirements.txt

  success "Core dependencies installed successfully"
}

# Update documentation
update_docs() {
  title "Updating documentation"

  cat >> docs/troubleshooting.md << 'EOF'

## Cloud CLI Dependency Conflicts

To resolve dependency conflicts between Azure CLI and OCI CLI (particularly related to jmespath),
we now use separate virtual environments for each cloud provider CLI.

### Using Cloud Provider CLIs

We've created wrapper scripts that automatically use the correct environment:

```bash
# For Azure CLI commands
./scripts/az login
./scripts/az account show

# For OCI CLI commands
./scripts/oci setup config
./scripts/oci iam compartment list
```

Alternatively, you can activate the specific virtual environment:

```bash
# For Azure CLI
source cloud_venvs/azure/bin/activate
az login

# For OCI CLI
source cloud_venvs/oci/bin/activate
oci setup config
```

### Setting Up Cloud CLI Environments

If you need to set up the environments manually:

```bash
# Set up Azure CLI environment
./scripts/setup-azure-cli.sh

# Set up OCI CLI environment
./scripts/setup-oci-cli.sh
```
EOF

  success "Updated troubleshooting documentation"
}

# Main function
main() {
  # Check if running in virtual environment
  check_venv

  # Backup requirements file
  backup_requirements

  # Fix dependency conflicts
  fix_jmespath_conflict

  # Create setup scripts
  create_azure_cli_setup
  create_oci_cli_setup

  # Create wrapper scripts
  create_azure_wrapper
  create_oci_wrapper

  # Install core dependencies
  install_core_deps

  # Update documentation
  update_docs

  echo ""
  title "Dependency Conflict Resolution Complete"
  success "Cloud CLI dependency conflicts have been resolved using separate environments!"
  echo ""
  echo "Core dependencies have been installed in your main virtual environment."
  echo "Cloud CLIs are now isolated in separate environments to avoid conflicts."
  echo ""
  echo "To use Azure CLI: ./scripts/az [commands]"
  echo "To use OCI CLI: ./scripts/oci [commands]"
  echo ""
  echo "See docs/troubleshooting.md for more details."
}

# Run main function
main
