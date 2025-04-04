# Cloud ELT Infrastructure

This repository contains the infrastructure as code for our cloud-based ELT (Extract, Load, Transform) platform. It supports both Azure and OCI cloud providers.

## Setup

1. Clone this repository
2. Set up virtual environment (recommended):
   ```bash
   ./scripts/setup-venv.sh
   source venv/bin/activate
   ```

3. Install required dependencies:
   - Ansible 2.9+
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
