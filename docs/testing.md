# Testing Framework

## Overview

This document describes the testing framework for the cloud-elt-infra project. The framework includes four main test scripts:

1. `test-playbook.sh` - Tests Ansible playbooks
2. `test-terraform.sh` - Tests Terraform configurations
3. `test-infra.sh` - Combined testing of both Ansible and Terraform
4. `validate-recovery.sh` - Validates infrastructure recovery after a disaster recovery event

## Test Scripts

### test-playbook.sh

This script tests Ansible playbooks with the following features:
- Creates an isolated test environment
- Generates a minimal test playbook
- Sets up necessary variable files
- Runs playbook in test mode
- Cleans up test environment

It avoids common Ansible issues:
- Handles the `environment` reserved variable name conflict by using `env_name` instead
- Prevents recursive template errors with simple Jinja2 expressions
- Avoids vault password file issues with a simplified test setup

Usage:
```bash
./scripts/test-playbook.sh <environment> [check|apply]
```

Example:
```bash
./scripts/test-playbook.sh dev check
```

The script creates:
- A temporary inventory with localhost as controller
- Basic variable files with environment-specific values
- A simple test playbook that verifies Ansible functionality

### test-terraform.sh

This script tests Terraform configurations with the following features:
- Format validation
- Syntax checking
- Plan generation
- State validation
- Resource verification

Usage:
```bash
./scripts/test-terraform.sh <environment> [plan|apply]
```

Example:
```bash
./scripts/test-terraform.sh dev plan
```

### test-infra.sh

This script combines both Ansible and Terraform testing with additional verification steps:
- Cloud provider connectivity
- Network setup verification
- Storage resources check
- Compute resources verification
- Service health monitoring

Usage:
```bash
./scripts/test-infra.sh <environment> [plan|apply]
```

Example:
```bash
./scripts/test-infra.sh dev plan
```

### validate-recovery.sh

This script validates infrastructure recovery after a disaster recovery event by checking:
- Resource group/compartment existence
- Virtual machine status
- Storage account/bucket status
- Databricks workspace/Airflow status
- Data Factory status

Usage:
```bash
./scripts/validate-recovery.sh [cloud_provider] [environment]
```

Example:
```bash
./scripts/validate-recovery.sh azure dev
```

The script performs the following checks:
- For Azure:
  - Resource Group existence
  - Virtual Machine running status
  - Storage Account existence
  - Databricks Workspace provisioning status
  - Data Factory provisioning status
- For OCI:
  - Compartment existence
  - Compute Instance running status
  - Object Storage Bucket existence
  - Airflow status (placeholder for future implementation)

## Verification Steps

### Ansible Verification
- Required files check
- Service status verification
- Python environment validation
- Cloud provider tools check
- Terraform installation verification
- SSH connectivity test

### Terraform Verification
- Resource creation check
- Resource attributes validation
- State file verification
- Resource dependencies check
- Plan warnings check

### Combined Verification
- Cloud provider connectivity
- Network setup verification
- Storage resources check
- Compute resources verification
- Service health monitoring

## Test Environment Setup

### Prerequisites
- Ansible installed
- Terraform installed
- Cloud provider CLI tools installed
- Python virtual environment
- SSH key pair

### Vault Password Files

The project uses environment-specific vault password files:
- Development: `.vault_pass_dev.txt`
- Production: `.vault_pass_prod.txt`

These files are:
- Generated using `setup-ansible-vault.sh`
- Stored outside version control
- Used with the `--vault-id` flag

Example:
```bash
# Generate vault password file
./scripts/setup-ansible-vault.sh dev

# Use vault password file
ansible-vault view --vault-id dev@.vault_pass_dev.txt ansible/group_vars/dev/vault.yml
```

### Environment Variables

Required environment variables:
- `CLOUD_PROVIDER` - Azure or OCI
- `ENVIRONMENT` or `env_name` - dev or prod
- `ANSIBLE_VAULT_PASSWORD_FILE` or `ANSIBLE_VAULT_ID_LIST` - Path to vault password file(s)

## Best Practices

1. Always run tests from the repository root directory
2. Use environment-specific vault password files
3. Keep sensitive data in encrypted vault files
4. Verify all resources after creation
5. Clean up resources after testing
6. Use the `--vault-id` flag for vault operations

## Troubleshooting

### Common Issues

1. Missing Vault Password File
   - Error: "Vault password file not found"
   - Solution: Run `setup-ansible-vault.sh` for your environment or set `CREATED_TEMP_VAULT=true` in the script

2. Vault Decryption Error
   - Error: "Decryption failed"
   - Solution: Verify vault password file content and permissions

3. Terraform State Error
   - Error: "State file not found"
   - Solution: Run `terraform init` first

4. Cloud Provider Authentication
   - Error: "Authentication failed"
   - Solution: Verify credentials in vault file

5. Environment Variable Conflicts
   - Error: "An unhandled exception occurred while templating '{{ environment }}'... recursive loop detected"
   - Solution: Use `env_name` instead of `environment` in Ansible templates and variables, as `environment` is a reserved Ansible variable

6. Terraform Module Reference Errors
   - Error: "Reference to undeclared module"
   - Solution: Use the correct module references with for_each: `module.azure_environment["azure"]` instead of `module.azure_environment[*]`

7. Storage Account Replication Type Error
   - Error: "Expected account_replication_type to be one of ['LRS', 'ZRS', ...]"
   - Solution: Make sure to use just the replication type (e.g., "LRS") without the account tier prefix

8. Local Variable Errors in Modules
   - Error: "Reference to undeclared local value"
   - Solution: Add missing `locals` blocks in module files with provider-specific logic

### Getting Help

- Check the [Ansible Documentation](https://docs.ansible.com/)
- Check the [Terraform Documentation](https://www.terraform.io/docs/)
- Contact the project maintainers

## Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Terraform Testing Documentation](https://www.terraform.io/docs/testing/index.html)
- [Cloud Provider Documentation](https://docs.microsoft.com/en-us/azure/) / [OCI Documentation](https://docs.cloud.oracle.com/)
