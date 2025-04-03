# Cloud ELT Infrastructure
A cloud infrastructure project for Extract, Load, and Transform (ELT) pipelines using Terraform and Ansible. Supports deployment to both OCI and Azure cloud platforms.

This repository provides Terraform configurations and automation scripts for deploying an ELT pipeline infrastructure on **OCI** and **Azure**. It includes:
- **Databricks** for data processing
- **Apache Airflow** (for OCI) or **Azure Data Factory** (for Azure) for workflow orchestration
- **Python ingestion scripts** for fetching data from external sources
- **dbt models** for transformation
- **Ansible automation** for controller VM setup

## 🔍 Prerequisites
Make sure all prerequisites are installed and configured before proceeding:

- Git
- Python 3.8+
- Ansible 2.9+
- Terraform 1.0+
- Valid cloud provider credentials (OCI or Azure)

## 🧰 Getting Started

### 1. Clone the Repository
```sh
git clone https://github.com/JanAhlin/cloud-elt-infra.git
cd cloud-elt-infra
```

### 2. Set Up Python Virtual Environment (Recommended)
We strongly recommend using a Python virtual environment for this project:

```sh
# Create and activate a virtual environment
./scripts/setup-venv.sh

# If already created, activate it manually:
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows
```

The virtual environment isolates your project dependencies and makes the installation of linters and other tools smoother. See [Virtual Environment Guide](docs/virtual-environment.md) for more details.

### 3. Install Required Tools
We provide scripts to simplify the installation of all required tools:

```sh
# Check if your environment has the required tools installed
./scripts/check-tools.sh

# Install all required tools automatically
./scripts/setup-environment.sh
```

If you prefer to install tools manually:

```sh
# Cloud CLIs
# Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

# Terraform
# Download from https://www.terraform.io/downloads.html
```

For detailed installation instructions, see [Installation Guide](docs/installation.md).

### 4. Configure Cloud Credentials

```sh
# For Azure
az login

# For OCI
oci setup config
```

### 5. Set Up Secure Credential Management

We use Ansible Vault to securely store and manage credentials. This approach ensures that sensitive information is never committed to version control.

```sh
# Set up Ansible Vault for dev environment
./scripts/setup-ansible-vault.sh dev

# Set up Ansible Vault for production environment
./scripts/setup-ansible-vault.sh prod
```

This will create an encrypted vault file where you can securely store your cloud credentials. The deployment process will automatically generate the necessary terraform.tfvars file from these credentials.

For detailed information about managing secrets and credentials, see [Secrets Management](docs/secrets-management.md).

### 6. Configure Terraform Variables

Terraform variables are managed through a combination of Ansible variables and vault files:

```sh
# Generate terraform.tfvars from Ansible variables
./scripts/generate-terraform-vars.sh dev
```

This will create the necessary `terraform.tfvars` file based on your Ansible configuration. For detailed information about Terraform configuration, see [Terraform Configuration](docs/terraform.md).

## 🔧 Configuration Options

### Basic Settings

You'll configure your deployment using two types of files:

1. **Regular Ansible variables** (`ansible/group_vars/all/vars.yml`) for non-sensitive settings:

```yaml
# Common settings
cloud_provider: "azure"  # or "oci"
environment: "dev"       # or "staging", "prod"
resource_prefix: "elt"
vpc_cidr: "10.0.0.0/16"
subnet_count: 3

# Azure-specific settings
azure_location: "eastus2"
storage_tier: "Standard_LRS"
databricks_sku: "standard"
vm_size: "Standard_B1s"
azure_storage_account_tier: "Standard"
azure_storage_min_tls_version: "TLS1_2"
azure_storage_container_access_type: "private"

# OCI-specific settings
oci_region: "us-ashburn-1"
compute_shape: "VM.Standard.E2.1.Micro"
oci_storage_tier: "Standard"
oci_storage_versioning: "Enabled"
oci_storage_auto_tiering: "Enabled"
oci_storage_lifecycle_days: 30
oci_compute_ocpus: 1
oci_compute_memory_gb: 1

# Databricks configuration
databricks_docker_port: 8443
databricks_docker_image: "databricks/community-edition"

# Monitoring configuration
log_retention_days: 30
alert_email_addresses: "your-email@example.com"
```

2. **Encrypted Ansible vault** (`ansible/group_vars/all/vault.yml`) for sensitive credentials:

```yaml
# Azure credentials
azure_subscription_id: "your-subscription-id"
azure_client_id: "your-client-id"
azure_client_secret: "your-client-secret"
azure_tenant_id: "your-tenant-id"

# OCI credentials
oci_tenancy_ocid: "your-tenancy-ocid"
oci_user_ocid: "your-user-ocid"
oci_fingerprint: "your-api-key-fingerprint"
ssh_public_key: "your-ssh-public-key-content"
```

For detailed configuration options, see [Configuration Guide](docs/configuration.md).

### Advanced Settings

You can also configure more advanced settings:

```yaml
# Network settings
vpc_cidr: "10.0.0.0/16"
subnet_count: 3

# High-performance resource sizing (Azure)
vm_size: "Standard_D4s_v3"
storage_tier: "Standard_LRS"
databricks_sku: "premium"
azure_storage_account_tier: "Premium"

# High-performance resource sizing (OCI)
compute_shape: "VM.Standard.E4.Flex"
storage_tier: "Standard"
oci_compute_ocpus: 4
oci_compute_memory_gb: 16
```

### Free Tier Optimizations

This project is configured to use free tier resources whenever possible. Key optimizations include:

- **Azure**: B1s VMs, Standard LRS storage, and economical Databricks configuration
- **OCI**: Always Free eligible VMs, minimal storage configuration, and free database options

For detailed information on free tier usage, see [Free Tier Usage Guide](docs/free-tier-usage.md).

## 📌 Repository Structure
```
/terraform
   ├── /modules
   │    ├── airflow/
   │    ├── data_factory/
   │    ├── databricks/
   │    ├── networking/
   │    ├── storage/
   │    └── compute/
   ├── /environments
   │    ├── oci/
   │    ├── azure/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
/ansible
   ├── /inventories
   │    ├── development/
   │    └── production/
   ├── /roles
   │    ├── common/
   │    ├── terraform/
   │    ├── azure_tools/
   │    ├── oci_tools/
   │    ├── python_tools/
   │    ├── controller_setup/
   │    └── infrastructure_deploy/
   ├── /playbooks
   │    ├── setup_controller.yml
   │    ├── deploy_azure_infra.yml
   │    ├── deploy_oci_infra.yml
   │    ├── check_infra_status.yml
   │    └── destroy_infra.yml
   └── ansible.cfg
/ingestion
   ├── api_ingestion.py
   ├── requirements.txt
/dbt_project
   ├── dbt_project.yml
/transformations
   ├── dbt_project.yml
```

## 🚀 Deployment Instructions

This project uses Ansible to fully automate infrastructure deployments, including the Terraform provisioning process:

### 1. Prepare Your Environment
After cloning the repository, create and configure your hosts file:

```sh
# Create your environment directory
mkdir -p ansible/inventories/development

# Copy the example hosts file
cp ansible/inventories/example/hosts.yml ansible/inventories/development/hosts.yml

# Edit the hosts file with your controller VM details
# You need to specify:
# - ansible_host: IP address of your controller VM
# - ansible_user: SSH user for connecting to the controller
# - ansible_ssh_private_key_file: Path to your SSH private key
# Optional settings:
# - ansible_ssh_pass: If using password authentication
# - ansible_become: true (if sudo access is needed)
# - ansible_become_pass: sudo password (if needed)
```

### 2. Deploy Infrastructure
Choose your target cloud provider and run the appropriate playbook:

For Azure:
```sh
# Using a vault password prompt
ansible-playbook -i ansible/inventories/development ansible/playbooks/deploy_azure_infra.yml --ask-vault-pass

# Using a vault password file
ansible-playbook -i ansible/inventories/development ansible/playbooks/deploy_azure_infra.yml --vault-password-file .vault_pass_dev.txt
```

For OCI:
```sh
# Using a vault password prompt
ansible-playbook -i ansible/inventories/development ansible/playbooks/deploy_oci_infra.yml --ask-vault-pass

# Using a vault password file
ansible-playbook -i ansible/inventories/development ansible/playbooks/deploy_oci_infra.yml --vault-password-file .vault_pass_dev.txt
```

The playbooks will:
1. Set up the controller VM
2. Configure cloud provider tools
3. Deploy the infrastructure using Terraform
4. Configure monitoring and logging

For detailed deployment instructions, see [Deployment Guide](docs/deployment.md).

## 🔒 Security Considerations

### Credential Management
- All sensitive credentials are stored in encrypted Ansible vault files
- Vault password files are never committed to version control
- Each environment has its own vault password file
- Terraform state files are stored securely in cloud storage

### Network Security
- VPCs are configured with minimal required access
- Security groups restrict access to necessary ports
- Private subnets are used for sensitive resources
- Public access is limited to required endpoints

### Monitoring and Logging
- Cloud provider monitoring tools are configured
- Logs are retained for 30 days by default
- Alerts are sent to configured email addresses
- Security events are logged and monitored

For detailed security information, see [Security Guide](docs/security.md).

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/contributing.md) for details on:
- How to submit pull requests
- Our coding standards
- The review process
- How to report issues

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
