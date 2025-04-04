# Installation Guide

This document provides detailed instructions for installing all the required tools and dependencies for the Cloud ELT Infrastructure project.

## Prerequisites

The following tools are required:

- Git
- Python 3.8+
- Ansible 2.9+
- Terraform 1.0+
- Cloud provider CLI tools (Azure CLI and/or OCI CLI)
- Security scanning tools (checkov, tfsec)

## Automated Installation

For convenience, we provide an automated installation script that will set up all the required tools:

```bash
# Make the script executable
chmod +x scripts/setup-environment.sh

# Run the installation script
./scripts/setup-environment.sh
```

The script will:
1. Detect your operating system
2. Install system dependencies
3. Set up a Python virtual environment
4. Install Ansible, Terraform, and security tools
5. Install cloud provider CLIs based on your selection
6. Configure pre-commit hooks

## Manual Installation

If you prefer to install tools manually, follow these instructions:

### 1. Install Git

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install git
```

**CentOS/RHEL/Fedora:**
```bash
sudo yum install git
```

**macOS:**
```bash
brew install git
```

### 2. Install Python 3.8+

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv
```

**CentOS/RHEL/Fedora:**
```bash
sudo yum install python3 python3-pip
```

**macOS:**
```bash
brew install python@3
```

### 3. Set up Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
python -m pip install --upgrade pip

# Install Python dependencies
pip install -r requirements.txt
```

### 4. Install Ansible

```bash
pip install "ansible>=2.9,<3.0"
```

### 5. Install Terraform

**Ubuntu/Debian:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform
```

**CentOS/RHEL/Fedora:**
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install terraform
```

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### 6. Install Azure CLI (if using Azure)

**Ubuntu/Debian:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**CentOS/RHEL/Fedora:**
```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
sudo yum install azure-cli
```

**macOS:**
```bash
brew install azure-cli
```

### 7. Install OCI CLI (if using OCI)

```bash
pip install oci-cli
```

### 8. Install Security Scanning Tools

```bash
# Install checkov
pip install checkov

# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
```

### 9. Configure Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
```

## Verifying Installations

You can verify your installations with these commands:

```bash
git --version
python --version
ansible --version
terraform --version
az --version       # Azure CLI
oci --version      # OCI CLI
checkov --version
tfsec --version
```

## Configuring Cloud Provider Credentials

### Azure

```bash
az login
```

### OCI

```bash
oci setup config
```

## Next Steps

After installing all the required tools:

1. Create and configure your cloud-specific variable files:
   ```bash
   cp example.azure-vars.yml azure-vars.yml  # For Azure deployments
   cp example.oci-vars.yml oci-vars.yml      # For OCI deployments
   ```

2. Deploy infrastructure using Ansible playbooks:
   ```bash
   # For Azure
   ansible-playbook ansible/playbooks/deploy_azure_infra.yml -e @azure-vars.yml

   # For OCI
   ansible-playbook ansible/playbooks/deploy_oci_infra.yml -e @oci-vars.yml
   ```
