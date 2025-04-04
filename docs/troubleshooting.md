# Troubleshooting Guide

This document provides solutions for common issues encountered while setting up and using the Cloud ELT Infrastructure project.

## Environment Setup Issues

### GPG Key Errors

If you encounter GPG key errors when running `apt-get update` or installing packages, such as:

```
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY XXXXXXXXXX
```

You can fix this by running our GPG key update script:

```bash
# Make the script executable
chmod +x scripts/fix-gpg-keys.sh

# Run the script with sudo
sudo ./scripts/fix-gpg-keys.sh
```

This script updates GPG keys for:
- GitHub CLI
- Kubernetes repositories
- HashiCorp (Terraform)
- Microsoft (Azure CLI)

If you need to update specific keys individually, we provide focused scripts for common repository issues:

#### Kubernetes Repository Issues

If you see errors like:
```
E: The repository 'https://apt.kubernetes.io kubernetes-xenial Release' does not have a Release file.
```

Run the Kubernetes repository fix script:
```bash
sudo ./scripts/fix-k8s-repo.sh
```

#### GitHub CLI Repository Issues

If you see errors related to the GitHub CLI repository:
```
The following signatures were invalid: EXPKEYSIG 23F3D4EA75716059 GitHub CLI <opensource+cli@github.com>
```

Run the GitHub CLI repository fix script:
```bash
sudo ./scripts/fix-github-cli-repo.sh
```

You can also modify the main fix-gpg-keys.sh script to run only the specific function you need by changing the `main()` function at the end of the script.

### Python Dependency Conflicts

If you encounter Python dependency conflicts, particularly with the `click` package or other dependencies, you can use our dependency resolution script:

```bash
# Make sure the script is executable
chmod +x scripts/upgrade-python-deps.sh

# Activate your virtual environment (if using one)
source venv/bin/activate

# Run the script
./scripts/upgrade-python-deps.sh
```

This script will:
1. Backup your current requirements.txt
2. Fix common conflicts, including the click version issue
3. Install dependencies with the fixed versions
4. Check for any remaining conflicts

Alternatively, you can create a new virtual environment with:

```bash
./scripts/setup-venv.sh
```

The updated setup script now uses pip-tools for better dependency resolution.

### Checkov Installation Issues

If you encounter issues with checkov installation (multiple versions being downloaded or dependency conflicts), you can use our fix scripts:

```bash
# Activate your virtual environment
source venv/bin/activate

# For general checkov installation issues:
./scripts/fix-checkov-simple.sh
```

If you encounter specific dependency conflicts with bc-python-hcl2, bc-detect-secrets, or other checkov dependencies, use:

```bash
# Activate your virtual environment
source venv/bin/activate

# For dependency conflicts:
./scripts/fix-checkov-deps.sh
```

These scripts:
1. Uninstall any existing checkov installation and its dependencies
2. Install compatible versions of all required packages
3. Update your requirements.txt file accordingly
4. Verify the installation

The scripts resolve common dependency conflicts that can occur when pip tries to install checkov and its dependencies with incompatible versions.

## Ansible Issues

### Ansible Configuration Not Found

If you encounter errors related to Ansible not finding the correct configuration file, ensure that you're using the correct `ansible.cfg` file in the `ansible` directory.

The scripts have been updated to set the `ANSIBLE_CONFIG` environment variable to use the correct configuration file:

```bash
export ANSIBLE_CONFIG="$(pwd)/ansible/ansible.cfg"
```

If you're running Ansible commands manually, you can set this environment variable yourself before running the commands.

### Ansible Collections Not Found

If Ansible can't find required collections, you might need to install them explicitly. Use the following command to install collections to your virtual environment:

```bash
# Activate your virtual environment
source venv/bin/activate

# Install collections
ansible-galaxy collection install ansible.posix:1.5.4
ansible-galaxy collection install community.general:9.1.0
```

## Terraform Issues

### Terraform Provider Installation Failures

If you encounter issues with Terraform provider installations, try clearing the provider cache:

```bash
rm -rf ~/.terraform.d/plugins
rm -rf .terraform
terraform init -upgrade
```

## Debugging Environment Setup

If you're having trouble with the setup scripts, you can run them with more verbose output:

```bash
# For environment setup
bash -x scripts/setup-environment.sh

# For virtual environment setup
bash -x scripts/setup-venv.sh
```

## Cloud CLI Dependency Conflicts

We've identified a fundamental dependency conflict between Azure CLI and OCI CLI, particularly related to the `jmespath` package:

- Azure CLI requires `jmespath>=0.7.1,<2.0.0`
- OCI CLI requires `jmespath==0.10.0` specifically

To resolve this conflict, we now use separate virtual environments for each cloud provider CLI.

### How Our Solution Works

Our solution isolates the conflicting dependencies by:

1. Maintaining separate requirement files:
   - `requirements.txt` - Core dependencies without cloud CLIs
   - `azure-requirements.txt` - Azure-specific requirements
   - `oci-requirements.txt` - OCI-specific requirements

2. Creating isolated virtual environments:
   - `cloud_venvs/azure/` - Dedicated environment for Azure CLI
   - `cloud_venvs/oci/` - Dedicated environment for OCI CLI

3. Providing convenient wrapper scripts:
   - `scripts/az` - Wrapper for Azure CLI commands
   - `scripts/oci` - Wrapper for OCI CLI commands

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

### Fixing the Environment Manually

If you encounter issues with the automatic setup, you can run our dedicated fix script:

```bash
# Make the script executable if needed
chmod +x scripts/fix-dependency-conflicts.sh

# Run the script to fix the dependency conflicts
./scripts/fix-dependency-conflicts.sh
```

This script will:
1. Back up your requirements.txt file
2. Create separate requirements files for each CLI
3. Set up the dedicated environments
4. Create the wrapper scripts
5. Install the core dependencies

### Alternative Solutions

If you prefer not to use separate environments, you could also try:

1. **Use constraints file**: Create a `constraints.txt` file that pins `jmespath==0.10.0` and install with:
   ```bash
   pip install -r requirements.txt -c constraints.txt
   ```

2. **Use a single environment with downgraded dependencies**: Remove one of the CLIs from requirements and install it separately:
   ```bash
   # Remove OCI and install core requirements
   pip install -r requirements.txt
   # Then install OCI CLI from PyPI
   pip install oci-cli
   ```

However, these alternatives may lead to other dependency conflicts over time.

## Reporting Issues

If you encounter an issue that isn't covered in this troubleshooting guide, please:

1. Check the logs in the `logs` directory (if available)
2. Review the script output for specific error messages
3. Report the issue to the project maintainers with:
   - The exact command that failed
   - The complete error message
   - Your operating system version
   - Any logs or script output
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
