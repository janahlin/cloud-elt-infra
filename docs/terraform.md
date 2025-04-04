# Terraform Configuration

This document describes how to configure and use Terraform in this project.

## Variable Management

We use a two-tier approach for managing Terraform variables:

1. **Non-sensitive variables** are stored in `ansible/group_vars/all/vars.yml`
2. **Sensitive variables** are stored in `ansible/group_vars/all/vault.yml` (encrypted)

The `terraform.tfvars` file is automatically generated from these sources using the `generate-terraform-vars.sh` script.

### Variable Files Structure

```
terraform/
├── terraform.tfvars          # Generated from Ansible vars (never committed)
└── variables.tf              # Variable declarations

ansible/
├── group_vars/
│   └── all/
│       ├── vars.yml         # Non-sensitive variables
│       └── vault.yml        # Encrypted sensitive variables
```

### Generating terraform.tfvars

To generate the `terraform.tfvars` file:

```bash
# Generate for development environment
./scripts/generate-terraform-vars.sh dev

# Generate for production environment
./scripts/generate-terraform-vars.sh prod
```

This script:
1. Reads non-sensitive values from `vars.yml`
2. Decrypts and reads sensitive values from `vault.yml`
3. Generates a properly formatted `terraform.tfvars` file

### Required Variables

#### Common Variables (vars.yml)
```yaml
cloud_provider: "azure"  # or "oci"
environment: "dev"       # or "staging", "prod"
resource_prefix: "elt"
vpc_cidr: "10.0.0.0/16"
subnet_count: 3
```

#### Azure Variables
- Non-sensitive (vars.yml):
```yaml
azure_location: "eastus2"
storage_tier: "Standard_LRS"
databricks_sku: "standard"
vm_size: "Standard_B1s"
azure_storage_account_tier: "Standard"
azure_storage_min_tls_version: "TLS1_2"
azure_storage_container_access_type: "private"
```

- Sensitive (vault.yml):
```yaml
azure_subscription_id: "your-subscription-id"
azure_client_id: "your-client-id"
azure_client_secret: "your-client-secret"
azure_tenant_id: "your-tenant-id"
```

#### OCI Variables
- Non-sensitive (vars.yml):
```yaml
oci_region: "us-ashburn-1"
compute_shape: "VM.Standard.E2.1.Micro"
oci_private_key_path: "~/.oci/oci_api_key.pem"
ssh_private_key_path: "~/.ssh/id_rsa"
oci_storage_tier: "Standard"
oci_storage_versioning: "Enabled"
oci_storage_auto_tiering: "Enabled"
oci_storage_lifecycle_days: 30
oci_compute_ocpus: 1
oci_compute_memory_gb: 1
```

- Sensitive (vault.yml):
```yaml
oci_tenancy_ocid: "your-tenancy-ocid"
oci_user_ocid: "your-user-ocid"
oci_fingerprint: "your-api-key-fingerprint"
ssh_public_key: "your-ssh-public-key-content"
```

#### Databricks Configuration
```yaml
databricks_docker_port: 8443
databricks_docker_image: "databricks/community-edition"
```

#### Monitoring Configuration
```yaml
log_retention_days: 30
alert_email_addresses: "your-email@example.com"
```

## Using Terraform

### Initial Setup

1. Generate terraform.tfvars:
```bash
./scripts/generate-terraform-vars.sh dev
```

2. Initialize Terraform:
```bash
cd terraform
terraform init
```

### Common Operations

```bash
# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

### Environment-Specific Operations

For environment-specific operations, use the `-var-file` flag:

```bash
# Plan for development
terraform plan -var-file=terraform.tfvars

# Apply for production
terraform apply -var-file=terraform.tfvars
```

## Best Practices

1. **Never commit sensitive data**
   - Keep `terraform.tfvars` in `.gitignore`
   - Use Ansible Vault for sensitive values

2. **Use environment-specific variables**
   - Generate separate `terraform.tfvars` for each environment
   - Use different vault passwords for each environment

3. **Version control**
   - Commit `variables.tf`
   - Never commit `terraform.tfvars`

4. **State management**
   - Use remote state storage
   - Enable state locking
   - Regularly backup state files

## Troubleshooting

### Common Issues

1. **Missing variables**
   - Ensure all required variables are in `vars.yml` or `vault.yml`
   - Check variable names match between Ansible and Terraform

2. **Vault decryption errors**
   - Verify vault password file exists
   - Check vault password file permissions
   - Ensure correct environment is specified

3. **Terraform errors**
   - Check variable types match declarations
   - Verify cloud provider credentials
   - Check resource quotas and limits

4. **Module reference errors**
   - Error: `Error: Reference to undeclared module`
   - Solution: When using conditional modules with `for_each`, reference them correctly:
     ```hcl
     # CORRECT:
     module.azure_environment["azure"].resource_group_name

     # INCORRECT:
     module.azure_environment[*].resource_group_name
     ```

5. **Storage account replication type errors**
   - Error: `Error: expected storage_account_replication_type to be one of [LRS ZRS GRS RAGRS], got Standard_LRS`
   - Solution: Use only the replication suffix without the tier prefix
     ```hcl
     # CORRECT:
     storage_account_replication_type = "LRS"

     # INCORRECT:
     storage_account_replication_type = "Standard_LRS"
     ```

6. **Local variable errors**
   - Error: `Error: Reference to undeclared local value`
   - Solution: Ensure each module has its required locals block:
     ```hcl
     locals {
       resource_name = "${var.prefix}-${var.environment}-resource"
     }
     ```

7. **Output reference errors**
   - Error: `Error: Unsupported attribute`
   - Solution: Use conditional expressions for outputs from conditional modules:
     ```hcl
     output "deployed_infrastructure" {
       value = var.cloud_provider == "azure" ? {
         resource_group = module.azure_environment["azure"].resource_group_name
         # other azure outputs
       } : {
         compartment = module.oci_environment["oci"].compartment_id
         # other oci outputs
       }
     }
     ```

### Getting Help

For additional help:
1. Check the [Terraform documentation](https://www.terraform.io/docs)
2. Review cloud provider documentation
3. Contact the project maintainers
