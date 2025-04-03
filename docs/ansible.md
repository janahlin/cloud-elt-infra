# Ansible Configuration

This document describes how to configure and use Ansible in this project.

## Variable Management

We use a two-tier approach for managing Ansible variables:

1. **Non-sensitive variables** are stored in `ansible/group_vars/all/vars.yml`
2. **Sensitive variables** are stored in `ansible/group_vars/all/vault.yml` (encrypted)

### Variable Files Structure

```
ansible/
├── group_vars/
│   ├── all/
│   │   ├── vars.yml         # Common non-sensitive variables
│   │   └── vault.yml        # Common encrypted sensitive variables
│   ├── dev/
│   │   ├── vars.yml         # Dev-specific non-sensitive variables
│   │   └── vault.yml        # Dev-specific encrypted sensitive variables
│   └── prod/
│       ├── vars.yml         # Prod-specific non-sensitive variables
│       └── vault.yml        # Prod-specific encrypted sensitive variables
├── playbooks/
│   ├── deploy_azure_infra.yml
│   ├── deploy_oci_infra.yml
│   └── destroy_infra.yml
└── ansible.cfg
```

## Ansible Configuration

The Ansible configuration file is located at `ansible/ansible.cfg`. Key configurations include:

```ini
[defaults]
inventory = ./inventories
roles_path = ./roles
vault_identity_list = dev@.vault_pass_dev.txt, prod@.vault_pass_prod.txt
```

## Playbooks

### Deployment Playbooks

- **`deploy_azure_infra.yml`**: Deploys Azure infrastructure
- **`deploy_oci_infra.yml`**: Deploys OCI infrastructure
- **`destroy_infra.yml`**: Destroys infrastructure in either cloud provider

### Example Usage

```bash
# Deploy Azure infrastructure in development environment
ansible-playbook playbooks/deploy_azure_infra.yml -e "env_name=dev" --vault-id dev@.vault_pass_dev.txt

# Deploy OCI infrastructure in production environment
ansible-playbook playbooks/deploy_oci_infra.yml -e "env_name=prod" --vault-id prod@.vault_pass_prod.txt
```

## Vault Management

### Creating Encrypted Files

```bash
# Create a new encrypted file
ansible-vault create --vault-id dev@.vault_pass_dev.txt group_vars/dev/vault.yml

# Edit an existing encrypted file
ansible-vault edit --vault-id dev@.vault_pass_dev.txt group_vars/dev/vault.yml
```

### Setting Up Vault Password

Use the provided script to set up your environment-specific vault password:

```bash
# Set up vault password for development environment
./scripts/setup-ansible-vault.sh dev

# Set up vault password for production environment
./scripts/setup-ansible-vault.sh prod
```

This script creates environment-specific vault password files like `.vault_pass_dev.txt` and `.vault_pass_prod.txt`.

## Best Practices

1. **Variable Naming**
   - Avoid using reserved variable names like `environment`
   - Use `env_name` instead of `environment` for environment variables
   - Prefix cloud-specific variables with cloud provider name

2. **Playbook Organization**
   - Keep playbooks focused on specific tasks
   - Use roles for shared functionality
   - Include tags for selective execution

3. **Vault Security**
   - Never commit vault passwords
   - Use different vault passwords for different environments
   - Rotate vault passwords regularly

## Troubleshooting

### Common Issues

1. **Recursive Loop in Template**
   - **Error**: 
     ```
     ERROR! Unexpected Exception, this is probably a bug: recursive loop detected in template string: {{ environment | default('dev') }}
     ```
   - **Solution**: Rename the `environment` variable to `env_name` as `environment` is a reserved variable name in Ansible.
   - **Fix example**:
     ```yaml
     # INCORRECT
     - name: Deploy resources
       include_tasks: deploy.yml
       vars:
         environment: "{{ environment | default('dev') }}"
     
     # CORRECT
     - name: Deploy resources
       include_tasks: deploy.yml
       vars:
         env_name: "{{ env_name | default('dev') }}"
     ```

2. **Missing Vault Password File**
   - **Error**: 
     ```
     ERROR! The vault password file ./.vault_pass_dev.txt was not found
     ```
   - **Solution**: Create the vault password file using the provided script:
     ```bash
     ./scripts/setup-ansible-vault.sh dev
     ```

3. **Invalid Inventory Structure**
   - **Error**:
     ```
     ERROR! Invalid inventory structure, expected a dictionary or list, got a <class 'ansible.parsing.yaml.objects.AnsibleMapping'>
     ```
   - **Solution**: Ensure your inventory file has the correct YAML structure:
     ```yaml
     # CORRECT
     all:
       children:
         dev:
           hosts:
             localhost:
     ```

### Getting Help

For additional help:
1. Check the [Ansible documentation](https://docs.ansible.com/)
2. Review cloud provider documentation
3. Contact the project maintainers 