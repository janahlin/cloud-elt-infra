# Cloud ELT Infrastructure

This repository contains the infrastructure as code for our cloud-based ELT (Extract, Load, Transform) platform. It supports both Azure and OCI cloud providers.

## Project Purpose

This project provides a complete infrastructure as code solution for setting up and managing cloud-based data processing environments. It automates the deployment of:

- **Data Extraction** pipelines that pull data from various sources
- **Data Loading** mechanisms that store data in cloud storage
- **Data Transformation** services that process and prepare data for analysis

### Key Benefits

- **Multi-Cloud Support**: Deploy to either Microsoft Azure or Oracle Cloud Infrastructure
- **Infrastructure as Code**: All resources are defined using Terraform and Ansible
- **Environment Isolation**: Separate configurations for development, staging, and production
- **Security-First**: Sensitive credentials are managed through Ansible Vault
- **Automated Testing**: Comprehensive test suite for validating infrastructure
- **Free Tier Optimization**: Configurations optimized for cloud provider free tiers

### Key Features

- **Automated Deployment**: One-command deployment of complete data processing infrastructure
- **Scalable Architecture**: Designed to scale from small datasets to enterprise workloads
- **Comprehensive Documentation**: Detailed guides for setup, usage, and troubleshooting
- **Security Best Practices**: Follows cloud security best practices and compliance standards
- **CI/CD Integration**: Ready for integration with continuous deployment pipelines

## Cloud Provider Differences

This project supports both Azure and OCI, with key differences in how data processing is implemented:

### Azure Implementation

Azure uses **Azure Data Factory** as the primary data integration service:

- **Managed Service**: Fully managed, serverless data integration service
- **Visual Authoring**: Pipeline development through a visual interface
- **Built-in Connectors**: Extensive library of pre-built connectors for various data sources
- **Integration with Azure Services**: Seamless integration with Azure Storage, SQL Database, etc.
- **Monitoring**: Built-in monitoring and alerting capabilities
- **Cost Model**: Pay-per-use pricing based on pipeline executions and data movement

### OCI Implementation

OCI uses **Apache Airflow** for data pipeline orchestration:

- **Open Source**: Based on the Apache Airflow open-source project
- **Code-First Approach**: Pipelines defined as Python code (DAGs)
- **Extensibility**: Highly extensible through custom operators and plugins
- **Community Ecosystem**: Access to a large ecosystem of community-contributed operators
- **Flexibility**: More control over pipeline execution and scheduling
- **Cost Model**: Based on compute resources allocated to the Airflow environment

### Choosing Between Providers

- **Choose Azure** if you prefer a fully managed service with visual development tools and minimal maintenance overhead
- **Choose OCI** if you need more flexibility, prefer code-based pipeline definitions, or have specific requirements for custom operators

Both implementations provide the same core ELT functionality but with different approaches to pipeline orchestration and management.

## Setup

1. Clone this repository
2. Set up virtual environment (recommended):
   ```bash
   ./scripts/setup-venv.sh
   source venv/bin/activate
   ```

3. Install required dependencies:
   - Ansible 2.17.10+
   - Terraform 1.0+
   - Azure CLI (for Azure deployments)
   - OCI CLI (for OCI deployments)

4. Set up your environment-specific vault password file:
   ```bash
   ./scripts/setup-ansible-vault.sh dev
   ```

5. Generate Terraform variables from Ansible:
   ```bash
   ./scripts/generate-terraform-vars.sh dev
   ```

## Common Issues and Solutions

### terraform.tfvars Not Being Used

If you encounter issues with Terraform prompting for variables that should be in terraform.tfvars:

1. Make sure to run `./scripts/generate-terraform-vars.sh dev` first
2. Use the `-var-file=terraform.tfvars` parameter when running Terraform commands manually

### Module Naming Issues

If you encounter errors related to modules like:

```
Error: Reference to undeclared module "environment"
```

This is because the modules are now called `azure_environment` and `oci_environment` with `for_each`. The outputs need to be referenced using:

```hcl
# Example of how to reference Azure outputs
module.azure_environment["azure"].resource_group_name

# Example of how to reference OCI outputs
module.oci_environment["oci"].compartment_id
```

### Ansible Collection Conflicts

If you see warnings about multiple versions of Ansible collections:

```
WARNING: Another version of 'ansible.posix' was found installed...
```

Run the fix script to install collections in the virtual environment:
```bash
./scripts/fix-ansible-collections.sh
```

### Circular Dependencies

If you encounter cycle errors like:

```
Error: Cycle: module.azure_environment.module.storage.oci_objectstorage_bucket.bucket, module.azure_environment.module.storage.oci_objectstorage_object_lifecycle_policy.lifecycle_policy
```

Remove the circular reference by editing the storage module.

### Ansible Reserved Variable Names

The `environment` name is reserved in Ansible. To avoid recursive template errors, use `env_name` in your variables and template expressions instead.

### TFLint Plugin Issues

If you encounter TFLint plugin initialization errors, run the linter with initialization:

```bash
./scripts/run-linters.sh --init-tflint
# Or to force reinstall plugins:
./scripts/run-linters.sh --force-init-tflint
```

## Testing

We have several test scripts to validate the infrastructure:

### Test Infrastructure

To test the complete infrastructure (both Terraform and Ansible) without applying changes:
```bash
./scripts/test-infra.sh dev
```

To test and apply changes (creates resources temporarily for testing):
```bash
./scripts/test-infra.sh dev apply
```

### Test Individual Components

To test just the Terraform configuration:
```bash
./scripts/test-terraform.sh dev terraform
```

To test just the Ansible playbooks:
```bash
./scripts/test-playbook.sh dev check
```

### Code Quality

To run all linters and check code quality:
```bash
./scripts/run-linters.sh
```

## Development Workflow

1. Update Ansible variables in `ansible/group_vars/all/vars.yml`
2. Encrypt sensitive variables in the appropriate vault file with:
   ```bash
   ANSIBLE_VAULT_IDENTITY_LIST="dev@.vault_pass_dev.txt" ansible-vault edit ansible/group_vars/dev/vault.yml
   ```
3. Generate updated Terraform variables:
   ```bash
   ./scripts/generate-terraform-vars.sh dev
   ```
4. Test your changes with `./scripts/test-infra.sh dev`
5. Deploy infrastructure with Ansible:
   ```bash
   ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/playbooks/deploy_azure_infra.yml
   ```
   or
   ```bash
   ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/playbooks/deploy_oci_infra.yml
   ```
   depending on your cloud provider.

## Environments

The platform supports the following environments:
- `dev` - Development environment
- `staging` - Pre-production testing
- `prod` - Production environment

## Cloud Providers

The infrastructure can be deployed to:
- Azure: Microsoft Azure cloud platform
- OCI: Oracle Cloud Infrastructure

The cloud provider is selected in the `vars.yml` file with the `cloud_provider` variable.

## Directory Structure

- `ansible/` - Ansible playbooks and configurations
- `terraform/` - Terraform modules and configurations
- `scripts/` - Utility scripts for development and deployment
- `docs/` - Additional documentation
- `.lintconfig/` - Linter configurations

## Documentation

For more detailed information, see the following documentation:

- [Ansible Configuration](docs/ansible.md) - Details on Ansible setup, variables, and troubleshooting
- [Terraform Configuration](docs/terraform.md) - Complete guide to Terraform usage and variable management
- [Testing Framework](docs/testing.md) - Information about testing scripts and troubleshooting
- [Secrets Management](docs/secrets-management.md) - How to manage sensitive variables securely
- [Installation Guide](docs/installation.md) - Detailed setup instructions
- [Free Tier Usage](docs/free-tier-usage.md) - How to deploy on cloud provider free tiers
- [Virtual Environment](docs/virtual-environment.md) - Setting up Python virtual environments
- [Linting](docs/linting.md) - Code quality checks and standards
