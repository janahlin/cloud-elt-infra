# Secrets Management

This document describes how to manage secrets and sensitive credentials in the Cloud ELT Infrastructure project.

## Overview

This project handles various sensitive credentials:

- Cloud provider API keys
- Service principal credentials
- SSH keys
- Database credentials
- Other access tokens

We use Ansible Vault to securely store and manage these secrets.

## Using Ansible Vault for Terraform Variables

This project uses Ansible Vault to securely manage credentials that are passed to Terraform. This approach offers several benefits:

1. Credentials are encrypted at rest
2. Different environments can have different credentials
3. No sensitive data in version control
4. Integrated with the existing Ansible automation

### Set Up Ansible Vault

We provide a script to set up Ansible Vault easily:

```bash
# Set up a vault for dev environment
./scripts/setup-ansible-vault.sh dev

# Set up a vault for production
./scripts/setup-ansible-vault.sh prod
```

The script will:
1. Create the necessary directory structure
2. Create a template vault file for you to edit
3. Encrypt the vault file with a password
4. Optionally save the password to a file (for automation)

### Structure of Secrets

The vault files are organized by environment:

```
ansible/
  group_vars/
    all/            # Shared across all environments
      vars.yml      # Non-sensitive variables
      vault.yml.example # Template for vault files
    dev/
      vault.yml     # Encrypted credentials for dev
    prod/
      vault.yml     # Encrypted credentials for production
```

Key variables stored in the vault:

```yaml
# Azure credentials
vault_azure_subscription_id: "your-subscription-id"
vault_azure_tenant_id: "your-tenant-id"
vault_azure_client_id: "your-client-id"         # For Service Principal auth
vault_azure_client_secret: "your-client-secret" # For Service Principal auth

# Authentication method
use_service_principal: false  # true = Service Principal, false = Managed Identity

# OCI credentials
vault_oci_tenancy_ocid: "your-tenancy-ocid"
vault_oci_user_ocid: "your-user-ocid"
vault_oci_fingerprint: "your-api-key-fingerprint"
```

### How It Works

1. The deployment playbooks include the vault files
2. A template task generates terraform.tfvars using Jinja2
3. Terraform uses these generated variables for deployment
4. No sensitive data is ever committed to version control

### Edit Vault Files

To edit an encrypted vault file:

```bash
# Edit the dev environment vault
ansible-vault edit ansible/group_vars/dev/vault.yml

# Edit the production environment vault
ansible-vault edit ansible/group_vars/prod/vault.yml
```

### Running Playbooks with Vault

When running playbooks, you need to provide the vault password:

```bash
# Using password prompt
ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/playbooks/deploy_azure_infra.yml --ask-vault-pass

# Using password file (default location)
ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/playbooks/deploy_azure_infra.yml --vault-password-file .vault_pass

# Using environment-specific password file
ansible-playbook -i ansible/inventories/prod/hosts.yml ansible/playbooks/deploy_azure_infra.yml --vault-password-file .vault_pass_prod
```

For production deployments, always use a separate vault file and password file:

```bash
# Set up production vault
./scripts/setup-ansible-vault.sh prod

# Run production deployment with production vault
ansible-playbook -i ansible/inventories/prod/hosts.yml ansible/playbooks/deploy_azure_infra.yml --vault-password-file .vault_pass_prod
```

## Other Security Best Practices

### SSH Keys

For OCI deployments, SSH keys are used to access instances. We recommend:

1. Generate a specific key pair for each environment
2. Store the public key in the vault
3. Keep the private key secure and not in version control

### Key Rotation

Regularly rotate all credentials:

1. Generate new credentials in your cloud provider
2. Update the vault files with the new credentials
3. Re-run the deployment to apply changes

### CI/CD Integration

For CI/CD pipelines:

1. Store the vault password as a CI/CD secret
2. Use the `--vault-password-file` option pointing to a file containing the secret
3. Ensure logs don't expose sensitive data with `no_log: true`

Example GitHub Actions workflow step:

```yaml
- name: Set up vault password
  run: echo "${{ secrets.VAULT_PASSWORD }}" > .vault_pass

- name: Run deployment
  run: |
    ansible-playbook -i ansible/inventories/prod/hosts.yml \
      ansible/playbooks/deploy_azure_infra.yml \
      --vault-password-file .vault_pass
```

## Azure Key Vault Integration

For production deployments, consider using Azure Key Vault:

1. Store all secrets in Azure Key Vault
2. Use managed identities for Azure resources to access Key Vault
3. Configure Ansible to retrieve secrets from Key Vault

Example Ansible task to retrieve a secret from Azure Key Vault:

```yaml
- name: Get secret from Azure Key Vault
  azure_rm_keyvaultsecret_info:
    vault_uri: "https://your-vault.vault.azure.net"
    name: your-secret-name
  register: keyvault_secret
```

## OCI Vault Integration

For OCI deployments, consider using OCI Vault:

1. Store secrets in OCI Vault
2. Use OCI Identity and Access Management (IAM) for access control
3. Configure Ansible to retrieve secrets from OCI Vault 