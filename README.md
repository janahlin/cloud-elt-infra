# Cloud ELT Infrastructure
A cloud infrastructure project for Extract, Load, and Transform (ELT) pipelines using Terraform and Ansible. Supports deployment to both OCI and Azure cloud platforms.


## 🔍 Prerequisites
Make sure all prerequisites are installed and configured before proceeding.

- Git
- Python 3.8+
- Ansible 2.9+
- Terraform 1.0+
- Valid cloud provider credentials (OCI or Azure)
## 🧰 Getting Started
1. Clone this repository:
   ```sh
   git clone https://github.com/JanAhlin/cloud-elt-infra.git
   cd cloud-elt-infra
   ```

2. Install required tools:
   ```sh
   # Python and pip
   python -m pip install --upgrade pip
   pip install -r requirements.txt

   # Terraform
   # Download from https://www.terraform.io/downloads.html

   # Ansible
   pip install ansible

   # Cloud CLIs
   # Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   # OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
   ```

3. Configure cloud credentials:
   ```sh
   # For Azure
   az login

   # For OCI
   oci setup config
   ```

4. Create your configuration file:
   ```sh
   cp config.example.yml config.yml
   # Edit config.yml with your settings
   ```

This repository provides Terraform configurations and automation scripts for deploying an ELT pipeline infrastructure on **OCI** and **Azure**. It includes:
- **Databricks** for data processing
- **Apache Airflow** (for OCI) or **Azure Data Factory** (for Azure) for workflow orchestration
- **Python ingestion scripts** for fetching data from external sources
- **dbt models** for transformation
- **Ansible automation** for controller VM setup


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

1. Prepare Your Environment:
   After cloning the repository, create and configure your hosts file:
   ```sh
   mkdir -p ansible/inventories/development
   cp ansible/inventories/example/hosts.yml ansible/inventories/development/hosts.yml
   # Edit ansible/inventories/development/hosts.yml with your controller VM details
   ```

2. Deploy Infrastructure:
   Choose your target cloud provider and run the appropriate playbook:

   For Azure:
   ```sh
   ansible-playbook -i ansible/inventories/development/hosts.yml ansible/playbooks/deploy_azure_infra.yml -e @azure-vars.yml
   ```

   For OCI:
   ```sh
   ansible-playbook -i ansible/inventories/development/hosts.yml ansible/playbooks/deploy_oci_infra.yml -e @oci-vars.yml
   ```

These playbooks will:
1. Clone the repository to the controller VM
2. Install required dependencies (Python, Terraform, cloud CLIs)
3. Configure authentication and credentials
4. Run infrastructure deployment scripts
5. Validate the deployment status

The sequence includes checks at each step to ensure successful completion before proceeding.

To verify the infrastructure post-deployment:
```sh
# View deployed resources
terraform show

# Check infrastructure status
./scripts/check-status.sh
```
1. Set up the controller VM with all required tools
2. Configure cloud provider credentials
3. Generate and apply Terraform configurations
4. Deploy the complete ELT infrastructure

## Infrastructure Management
After deployment, you can manage your infrastructure using these commands:

## 🔧 Configuration Options

1. Clone the repository and set up your environment:
   ```sh
   git clone https://github.com/JanAhlin/cloud-elt-infra.git
   cd cloud-elt-infra
   ```

2. Create and configure your cloud-specific variable files:
   ```sh
   cp example.azure-vars.yml azure-vars.yml  # For Azure deployments
   cp example.oci-vars.yml oci-vars.yml      # For OCI deployments
   ```

3. Configure your cloud provider credentials:

   For Azure (`azure-vars.yml`):
   ```yaml
   # Environment settings
   environment: "dev"
   resource_prefix: "elt"
   auto_approve: false

   # Azure credentials
   azure_subscription_id: "<your-subscription-id>"
   azure_tenant_id: "<your-tenant-id>"
   azure_location: "eastus2"

   # Resource configuration
   vm_size: "Standard_D4s_v3"
   storage_tier: "Standard_LRS"
   databricks_sku: "premium"
   ```

   For OCI (`oci-vars.yml`):
   ```yaml
   # Environment settings
   environment: "dev"
   resource_prefix: "elt"
   auto_approve: false

   # OCI credentials
   oci_tenancy_ocid: "<your-tenancy-ocid>"
   oci_compartment_id: "<your-compartment-id>"
   oci_region: "us-ashburn-1"

   # Resource configuration
   compute_shape: "VM.Standard.E4.Flex"
   storage_tier: "Standard"
   ```

Important security notes:
- Never commit credential files to version control
- Use environment variables or secure vaults in production
- Add `*-vars.yml` to your `.gitignore`

The infrastructure deployment will automatically configure:
- Azure Data Factory for Azure deployments
- Apache Airflow for OCI deployments
```yaml
# Common Configuration Settings

## Initial Setup
1. Fork and clone the repository:
   ```sh
   git clone https://github.com/YourUsername/cloud-elt-infra.git
   cd cloud-elt-infra
   ```

2. Create configuration files:
   ```sh
   cp example.azure-vars.yml azure-vars.yml
   cp example.oci-vars.yml oci-vars.yml
   ```

# Configuration Settings

## Basic Settings
```yaml
# Environment settings
environment: "dev"      # Options: dev, staging, prod
auto_approve: false     # Set true to skip Terraform prompts
resource_prefix: "elt"  # Prefix for all resource names

# Resource sizing
vm_size: "Standard_D4s_v3"
storage_tier: "Standard_LRS"
## Basic Settings
```yaml
# Common environment settings
environment: "dev"      # Options: dev, staging, prod
auto_approve: false     # Set true to skip Terraform prompts
resource_prefix: "elt"  # Prefix for all resource names

# Resource sizing (Azure)
vm_size: "Standard_D4s_v3"
storage_tier: "Standard_LRS"
databricks_sku: "premium"

# Resource sizing (OCI)
compute_shape: "VM.Standard.E4.Flex"
storage_tier: "Standard"

# Network settings
vpc_cidr: "10.0.0.0/16"
subnet_count: 3
```

## Cloud Provider Settings
Configure your chosen cloud provider:

For Azure (`azure-vars.yml`):
```yaml
# Azure credentials
subscription_id: "<subscription-id>"
tenant_id: "<tenant-id>"
location: "eastus2"
```

For OCI (`oci-vars.yml`):
```yaml
# OCI credentials
tenancy_ocid: "<tenancy-ocid>"
compartment_id: "<compartment-id>"
region: "us-ashburn-1"
```

The configuration files contain sensitive information. Make sure to:
1. Never commit credential files to version control
2. Use environment variables or secure vaults in production
3. Keep the `*-vars.yml` files in your `.gitignore`
environment: "dev"
auto_approve: false  # Set to true to skip confirmation prompts

# Azure credentials
azure_subscription_id: "your-subscription-id"
azure_client_id: "your-client-id"
azure_client_secret: "your-client-secret"
azure_tenant_id: "your-tenant-id"
azure_location: "eastus2"

# Resource configuration
databricks_sku: "premium"
```
Example oci-vars.yml:
```yaml
# Common settings
environment: "dev"
auto_approve: false

# OCI credentials
oci_tenancy_ocid: "your-tenancy-ocid"
oci_user_ocid: "your-user-ocid"
oci_fingerprint: "your-api-key-fingerprint"
oci_region: "us-ashburn-1"
```

Cloud-Specific Options
The infrastructure deployment will automatically select:

Azure Data Factory for Azure deployments
Apache Airflow for OCI deployments
🔄 Advanced Usage
## Advanced Usage

### Partial Deployments
You can deploy specific components of the infrastructure:

1. Deploy only networking:
   ```sh
   ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "networking" -e @azure-vars.yml
   # or for OCI
   ansible-playbook ansible/playbooks/deploy_oci_infra.yml --tags "networking" -e @oci-vars.yml
   ```

2. Deploy only compute resources:
   ```sh
   ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "compute" -e @azure-vars.yml
   # or for OCI
   ansible-playbook ansible/playbooks/deploy_oci_infra.yml --tags "compute" -e @oci-vars.yml
   ```

3. Update specific components:
   ```sh
   ansible-playbook ansible/playbooks/deploy_azure_infra.yml --tags "update,databricks" -e @azure-vars.yml
   # or for OCI
   ansible-playbook ansible/playbooks/deploy_oci_infra.yml --tags "update,airflow" -e @oci-vars.yml
   ```

### Infrastructure Management
Common management tasks:

1. Check infrastructure status:
   ```sh
   ansible-playbook ansible/playbooks/check_infra_status.yml -i ansible/inventories/development/hosts.yml
   ```

2. Destroy infrastructure:
   ```sh
   ansible-playbook ansible/playbooks/destroy_infra.yml -i ansible/inventories/development/hosts.yml
   ```

Customizing the Deployment
The modular design allows you to customize your infrastructure:

1. Modify Terraform modules in /terraform/modules/
2. Create custom Ansible roles in roles
3. Update variable templates in templates


## 📜 License

This project is licensed under the MIT License.
