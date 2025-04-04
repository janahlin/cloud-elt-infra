# Secrets Management

## Overview
This document describes how to manage sensitive credentials and secrets in the cloud-elt-infra project using Ansible Vault.

## Vault Structure
The project uses environment-specific vault files located in `ansible/group_vars/<environment>/vault.yml`. A template file is provided at `ansible/group_vars/all/vault.yml.example` that shows the required structure and variables.

### Environment-Specific Vaults
- Development: `ansible/group_vars/dev/vault.yml`
- Production: `ansible/group_vars/prod/vault.yml`
- Staging: `ansible/group_vars/staging/vault.yml`

## Setting Up Vault Files

### Using the Setup Script
The project provides a script to help set up vault files:

```bash
# For development environment
./scripts/setup-ansible-vault.sh dev

# For production environment
./scripts/setup-ansible-vault.sh prod
```

This script will:
1. Create a new vault file from the template
2. Prompt for the vault password
3. Help you encrypt the file

### Manual Setup
If you prefer to set up manually:

1. Copy the template:
```bash
cp ansible/group_vars/all/vault.yml.example ansible/group_vars/<environment>/vault.yml
```

2. Edit the vault file with your secrets:
```bash
ansible-vault edit ansible/group_vars/<environment>/vault.yml
```

3. Encrypt the file:
```bash
ansible-vault encrypt ansible/group_vars/<environment>/vault.yml
```

## Vault Variables
The vault template includes the following sections:

### Azure Credentials
- `vault_azure_subscription_id`: Azure subscription ID
- `vault_azure_tenant_id`: Azure tenant ID
- `vault_azure_client_id`: Service principal client ID
- `vault_azure_client_secret`: Service principal client secret
- `use_service_principal`: Boolean flag for authentication method

### OCI Credentials
- `vault_oci_tenancy_ocid`: OCI tenancy OCID
- `vault_oci_user_ocid`: OCI user OCID
- `vault_oci_fingerprint`: API key fingerprint
- `vault_oci_private_key`: API private key content
- `vault_oci_ssh_private_key`: SSH private key for OCI instances

### OCI Database Credentials
- `vault_oci_db_username`: OCI database username
- `vault_oci_db_password`: OCI database password
- `vault_oci_db_host`: OCI database host
- `vault_oci_db_port`: OCI database port
- `vault_oci_db_name`: OCI database name

### Azure Database Credentials
- `vault_azure_db_username`: Azure database username
- `vault_azure_db_password`: Azure database password
- `vault_azure_db_host`: Azure database host
- `vault_azure_db_port`: Azure database port
- `vault_azure_db_name`: Azure database name

### Notification Settings
- `vault_notification_emails`: List of email addresses for notifications

## Best Practices

### 1. Password Management
- Use different vault passwords for each environment
- Store vault passwords securely
- Never commit vault passwords to version control

### 2. Key Rotation
- Regularly rotate service principal credentials
- Update vault files when credentials change
- Document key rotation procedures

### 3. CI/CD Integration
- Use environment variables for vault passwords in CI/CD
- Never expose vault contents in logs or artifacts
- Use separate vault files for each environment

### 4. Security
- Keep vault files encrypted at all times
- Use strong passwords for vault files
- Limit access to vault files to authorized personnel only

## Troubleshooting

### Common Issues
1. **Vault Password Issues**
   - Ensure you're using the correct password file
   - Check file permissions on password files
   - Verify password file location

2. **Encryption/Decryption Problems**
   - Make sure vault files are properly encrypted
   - Check for file corruption
   - Verify vault password is correct

3. **Variable Access Issues**
   - Ensure variables are properly prefixed with `vault_`
   - Check variable names match exactly
   - Verify vault file is in correct location

## Additional Resources
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Azure Service Principal Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)
- [OCI API Key Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
