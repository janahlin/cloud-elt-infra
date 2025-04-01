# Secrets Management Guide

This document provides detailed information on how to securely manage credentials and other sensitive information in the Cloud ELT Infrastructure project.

## Overview

The project uses two primary methods for managing secrets:

1. **Ansible Vault** - For encrypting sensitive variables used in Ansible playbooks
2. **GitHub Secrets** - For securely storing credentials used in GitHub Actions workflows

Both methods ensure that sensitive information is never stored in plain text within your codebase.

## Ansible Vault

### Setting Up Ansible Vault

We provide a helper script that automates the setup of Ansible Vault:

```bash
# Set up vault for dev environment
./scripts/setup-vault.sh dev

# Set up vault for production environment
./scripts/setup-vault.sh prod
```

The script will:
1. Create a password file for the vault (`.vault_pass_[env].txt`)
2. Create a vault variables file from the template
3. Encrypt the variables file
4. Update `.gitignore` to exclude password files

### Manually Setting Up Ansible Vault

If you prefer to set up Ansible Vault manually:

1. Create a vault password file:
   ```bash
   echo "your-secure-password" > .vault_pass.txt
   chmod 600 .vault_pass.txt
   ```

2. Create a vault variables file:
   ```bash
   mkdir -p ansible/group_vars/dev
   cp ansible/group_vars/vault_template.yml ansible/group_vars/dev/vault.yml
   ```

3. Edit the vault variables file with your sensitive information:
   ```bash
   # Edit the file with your credentials
   vi ansible/group_vars/dev/vault.yml
   ```

4. Encrypt the vault file:
   ```bash
   ansible-vault encrypt --vault-password-file .vault_pass.txt ansible/group_vars/dev/vault.yml
   ```

### Using Ansible Vault

To use encrypted variables in playbooks:

1. View encrypted variables:
   ```bash
   ansible-vault view --vault-password-file .vault_pass.txt ansible/group_vars/dev/vault.yml
   ```

2. Edit encrypted variables:
   ```bash
   ansible-vault edit --vault-password-file .vault_pass.txt ansible/group_vars/dev/vault.yml
   ```

3. Run playbooks with encrypted variables:
   ```bash
   ansible-playbook -i ansible/inventories/dev/hosts.yml --vault-password-file .vault_pass.txt ansible/playbooks/deploy_azure_infra.yml
   ```

## GitHub Secrets

GitHub Secrets provide a secure way to store sensitive information for use in GitHub Actions workflows.

### Required GitHub Secrets

For this project, you need to set up the following secrets in your GitHub repository:

#### Common Secrets
- `VAULT_PASSWORD` - Password for Ansible Vault encryption
- `RESOURCE_PREFIX` - Prefix for all resource names (e.g., "elt")
- `ANSIBLE_INVENTORY` - Content of your Ansible inventory file
- `DB_USERNAME` - Database username (if applicable)
- `DB_PASSWORD` - Database password (if applicable)
- `NOTIFICATION_EMAIL` - Email for notifications

#### Azure-specific Secrets
- `AZURE_CREDENTIALS` - JSON containing Azure service principal credentials
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `AZURE_TENANT_ID` - Azure Tenant ID
- `AZURE_CLIENT_ID` - Azure Client ID
- `AZURE_CLIENT_SECRET` - Azure Client Secret
- `AZURE_LOCATION` - Azure region (e.g., "eastus2")
- `AZURE_VM_SIZE` - Azure VM size (e.g., "Standard_B1s")
- `AZURE_STORAGE_TIER` - Azure storage tier (e.g., "Standard_LRS")
- `AZURE_DATABRICKS_SKU` - Azure Databricks SKU (e.g., "standard")

#### OCI-specific Secrets
- `OCI_CONFIG` - Content of OCI config file
- `OCI_PRIVATE_KEY` - OCI API private key
- `OCI_TENANCY_OCID` - OCI Tenancy OCID
- `OCI_USER_OCID` - OCI User OCID
- `OCI_FINGERPRINT` - OCI API Key fingerprint
- `OCI_REGION` - OCI region (e.g., "us-ashburn-1")
- `OCI_COMPUTE_SHAPE` - OCI compute shape (e.g., "VM.Standard.E2.1.Micro")

### Setting Up GitHub Secrets

1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**
2. Click **New repository secret**
3. Enter the name and value for each secret
4. Click **Add secret**

### Creating Azure Credentials JSON

For the `AZURE_CREDENTIALS` secret, you need to create a JSON containing Azure service principal credentials:

```bash
# Create a service principal with Azure CLI
az ad sp create-for-rbac --name "cloud-elt-infra" --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# The output will be JSON in the format:
# {
#   "clientId": "...",
#   "clientSecret": "...",
#   "subscriptionId": "...",
#   "tenantId": "...",
#   "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
#   "resourceManagerEndpointUrl": "https://management.azure.com/",
#   "activeDirectoryGraphResourceId": "https://graph.windows.net/",
#   "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
#   "galleryEndpointUrl": "https://gallery.azure.com/",
#   "managementEndpointUrl": "https://management.core.windows.net/"
# }
```

Copy this entire JSON as the value for the `AZURE_CREDENTIALS` secret.

## Best Practices

1. **Never commit secrets to version control**
   - Ensure `.vault_pass*.txt` files are in `.gitignore`
   - Check that vault-encrypted files are indeed encrypted before committing

2. **Rotate credentials regularly**
   - Update all credentials every 60-90 days
   - Immediately rotate credentials for any team members who leave

3. **Use least-privilege principle**
   - Create service principals with only the permissions they need
   - Restrict access to specific resource groups where possible

4. **Monitor for exposed secrets**
   - Use tools like GitHub's secret scanning
   - Implement notifications for potential credential leaks

5. **Separate environments**
   - Use different credentials for dev, staging, and production
   - Create separate vault files for each environment

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

# Using password file
ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/playbooks/deploy_azure_infra.yml --vault-password-file .vault_pass
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