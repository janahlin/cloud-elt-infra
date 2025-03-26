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