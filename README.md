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

### 5. Create Configuration Files

```sh
# Copy the example Terraform variables file
cp terraform.tfvars.example terraform.tfvars
```

Edit the terraform.tfvars file with your specific settings for either Azure or OCI deployment.

## 🔧 Configuration Options

### Basic Settings

Your terraform.tfvars file should include the appropriate settings for your target platform:

```hcl
# Common settings
environment     = "dev"
resource_prefix = "elt"
auto_approve    = false

# Uncomment and configure the section for your chosen cloud provider:

# Azure configuration
# azure_subscription_id = "your-subscription-id"
# azure_tenant_id       = "your-tenant-id"
# azure_location        = "eastus2"
# vm_size               = "Standard_B1s"        # Free tier eligible
# storage_tier          = "Standard_LRS"        # Free tier eligible
# databricks_sku        = "standard"            # More economical than premium

# OCI configuration
# oci_tenancy_ocid      = "your-tenancy-ocid"
# oci_compartment_id    = "your-compartment-id"
# oci_region            = "us-ashburn-1"        # Region with good free tier support
# compute_shape         = "VM.Standard.E2.1.Micro" # Always Free eligible
# storage_tier          = "Standard"
```

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

# High-performance resource sizing (OCI)
compute_shape: "VM.Standard.E4.Flex"
storage_tier: "Standard"
```

### Free Tier Optimizations

This project is configured to use free tier resources whenever possible. Key optimizations include:

- **Azure**: B1s VMs, Standard LRS storage, and economical Databricks configuration
- **OCI**: Always Free eligible VMs, minimal storage configuration, and free database options

For detailed information on free tier usage, see [Free Tier Usage Guide](docs/free-tier-usage.md).

Important security notes:
- Never commit credential files to version control
- Use environment variables or secure vaults in production
- Add `*-vars.yml` to your `.gitignore`

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
mkdir -p ansible/inventories/development
cp ansible/inventories/example/hosts.yml ansible/inventories/development/hosts.yml
# Edit ansible/inventories/development/hosts.yml with your controller VM details
```

### 2. Deploy Infrastructure
Choose your target cloud provider and run the appropriate playbook:

For Azure:
```sh
ansible-playbook -i ansible/inventories/development/hosts.yml ansible/playbooks/deploy_azure_infra.yml -e @terraform.tfvars
```

For OCI:
```sh
ansible-playbook -i ansible/inventories/development/hosts.yml ansible/playbooks/deploy_oci_infra.yml -e @terraform.tfvars
```

These playbooks will:
1. Clone the repository to the controller VM
2. Install required dependencies (Python, Terraform, cloud CLIs)
3. Configure authentication and credentials
4. Run infrastructure deployment scripts
5. Validate the deployment status

### 3. Verify Deployment
To verify the infrastructure post-deployment:
```sh
# View deployed resources
terraform show

# Check infrastructure status
./scripts/check-status.sh
```

## 🔄 Infrastructure Management

### Partial Deployments
You can deploy specific components of the infrastructure:

```sh
# Deploy only networking
ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "networking" -e @terraform.tfvars

# Deploy only compute resources
ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "compute" -e @terraform.tfvars

# Update specific components
ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "update,databricks" -e @terraform.tfvars
```

Replace `deploy_azure_infra.yml` with `deploy_oci_infra.yml` for OCI deployments.

### Common Management Tasks

```sh
# Check infrastructure status
ansible-playbook ansible/playbooks/check_infra_status.yml -i ansible/inventories/development/hosts.yml

# Destroy infrastructure
ansible-playbook ansible/playbooks/destroy_infra.yml -i ansible/inventories/development/hosts.yml
```

### Customizing the Deployment
The modular design allows you to customize your infrastructure:

1. Modify Terraform modules in `/terraform/modules/`
2. Create custom Ansible roles in `ansible/roles/`
3. Update variable templates in `templates/`

## 🔒 Security & Compliance
This project implements several security best practices:

- Least privilege access model for all cloud resources
- Network security groups and firewalls to restrict access
- Encryption for data at rest and in transit
- Infrastructure security scanning with tfsec and checkov
- Secure credentials management with Ansible Vault and GitHub Secrets
- Comprehensive code quality checks with multiple linters

### Security Scans
```sh
# Activate your virtual environment first
source venv/bin/activate

# Install security scanning tools
pip install checkov
pip install tfsec

# Run scans
checkov -d terraform/
tfsec terraform/
```

### Code Quality

We use multiple linters to ensure code quality:

```sh
# Activate your virtual environment first
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows

# Install all linters
./scripts/install-linters.sh

# Run all linters
./scripts/run-linters.sh
```

Our linting suite includes:
- **TFLint** for Terraform
- **ansible-lint** for Ansible
- **Pylint** for Python
- **ShellCheck** for shell scripts
- **yamllint** for YAML files

For more details, see [Linting Configuration](docs/linting.md).

### Secrets Management

We provide tools and documentation for secure credential management:

```sh
# Set up Ansible Vault for secure credential storage
./scripts/setup-vault.sh dev  # For dev environment
./scripts/setup-vault.sh prod # For production environment
```

GitHub Actions workflows are configured to use GitHub Secrets for all sensitive information.

For detailed information, see [Secrets Management Guide](docs/secrets-management.md).

## 📊 Monitoring & Observability
The infrastructure includes monitoring components:

- Centralized logging via Log Analytics Workspace (Azure) or OCI Logging
- Metric collection and dashboards 
- Alerting configuration for critical components

See `terraform/modules/monitoring` for implementation details.

## 🔄 CI/CD Integration
The repository includes CI/CD pipeline configurations:

- GitHub Actions workflows for testing and deployment
- Azure DevOps pipeline example
- Pre-commit hooks for code quality

See `.github/workflows` directory for GitHub Actions configurations.

## 📜 License

This project is licensed under the MIT License.
