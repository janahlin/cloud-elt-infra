# Testing Framework

## Overview

This document describes the testing framework for the cloud-elt-infra project. The framework includes three main test scripts:

1. `test-playbook.sh` - Tests Ansible playbooks
2. `test-terraform.sh` - Tests Terraform configurations
3. `test-infra.sh` - Combined testing of both Ansible and Terraform

## Test Scripts

### test-playbook.sh

This script tests Ansible playbooks with the following features:
- Syntax checking
- Linting
- Dry-run execution
- Full execution with verification

Usage:
```bash
./scripts/test-playbook.sh <environment> [plan|apply]
```

Example:
```bash
./scripts/test-playbook.sh dev plan
```

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
- `ENVIRONMENT` - dev or prod
- `VAULT_PASSWORD_FILE` - Path to vault password file

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
   - Solution: Run `setup-ansible-vault.sh` for your environment

2. Vault Decryption Error
   - Error: "Decryption failed"
   - Solution: Verify vault password file content and permissions

3. Terraform State Error
   - Error: "State file not found"
   - Solution: Run `terraform init` first

4. Cloud Provider Authentication
   - Error: "Authentication failed"
   - Solution: Verify credentials in vault file

### Getting Help

- Check the [Ansible Documentation](https://docs.ansible.com/)
- Check the [Terraform Documentation](https://www.terraform.io/docs/)
- Contact the project maintainers

## Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Terraform Testing Documentation](https://www.terraform.io/docs/testing/index.html)
- [Cloud Provider Documentation](https://docs.microsoft.com/en-us/azure/) / [OCI Documentation](https://docs.cloud.oracle.com/) 