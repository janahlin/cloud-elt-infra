# Free Tier Usage Guide

This document provides detailed information on how to optimize your deployment to use free tier resources on both Azure and OCI (Oracle Cloud Infrastructure).

## Free Tier Overview

### Azure Free Tier
Azure offers a free tier that includes:
- 12 months of popular free services
- $200 credit for the first 30 days
- 25+ services that are always free

Key free resources we use:
- B1s virtual machines (750 hours/month for 12 months)
- 5 GB of standard blob storage
- 10 Standard storage transactions per month
- Basic networking services

### OCI Always Free Tier
OCI offers an Always Free tier that includes:
- 2 AMD-based Compute VMs (VM.Standard.E2.1.Micro) with 1 OCPU and 1 GB RAM each
- 2 Block Volumes (50 GB total)
- 10 GB Object Storage
- 10 GB Archive Storage
- 1 Autonomous Database with 1 OCPU and 20 GB storage
- Load Balancer (1 instance)
- Monitoring and Notifications

## Free Tier Configuration

The project is configured to use free tier resources where possible. Key configurations include:

### Compute Resources

#### Azure
```hcl
vm_size = "Standard_B1s" # Free tier eligible VM size
```

The B1s is the smallest general-purpose VM size eligible for the Azure free tier. It provides:
- 1 vCPU
- 1 GB RAM
- 4 GB temporary storage

#### OCI
```hcl
compute_shape = "VM.Standard.E2.1.Micro" # Always Free Tier eligible
shape_config {
  ocpus = 1
  memory_in_gbs = 1
}
```

This configuration uses the Always Free tier eligible VM shape with minimum required resources.

### Storage Resources

#### Azure
```hcl
account_tier = "Standard"
account_replication_type = "LRS" # Locally Redundant Storage for free tier
```

Standard storage with local redundancy is the most economical option and available in the free tier.

#### OCI
```hcl
storage_tier = "Standard"
versioning = "Disabled"
auto_tiering = "Disabled"
```

Standard storage without versioning or auto-tiering helps stay within free tier limits.

### Data Processing

#### Azure
Instead of using premium Databricks, we use:
```hcl
databricks_sku = "standard" # Standard tier is more economical than premium
```

Key optimizations:
- Auto-terminate clusters after 20 minutes of inactivity
- Use minimum worker nodes (1)
- Use standard SKU instead of premium

#### OCI
Since OCI doesn't have a free Databricks equivalent, we set up a basic Jupyter notebook environment:
```hcl
# Basic data processing environment as a free alternative
pip3 install jupyter pandas scikit-learn matplotlib dask
```

### Lifecycle Policies

To manage storage and stay within free tier limits:
- Object lifecycle policies to delete old objects after 30 days
- Boot volume backup policies set to minimum required frequency
- Minimal boot volume sizes (50 GB or less)

## Best Practices for Free Tier Usage

1. **Use Scheduled Shutdown/Startup**
   - Shut down VMs when not in use
   - Use automation scripts to start/stop resources on a schedule

2. **Monitor Usage Regularly**
   - Set up alerts for approaching free tier limits
   - Check usage dashboards weekly

3. **Clean Up Temporary Resources**
   - Delete temporary storage blobs/objects
   - Remove unused resources

4. **Optimize Compute Usage**
   - Set auto-shutdown for dev/test environments
   - Scale to zero when possible

5. **Stay Within Storage Limits**
   - Monitor storage usage
   - Implement retention policies to automatically delete old data

## Important Limitations

### Azure
- Free tier benefits expire after 12 months
- $200 credit is only available for the first 30 days
- Limited to basic monitoring capabilities

### OCI
- Always Free resources are limited to specific regions
- Only specific VM shapes are eligible
- Compute instances have limited performance

## Upgrading Beyond Free Tier

When your workload grows beyond what the free tier can handle:

1. Modify these variables in your deployment:
   ```hcl
   # Azure
   vm_size = "Standard_D2s_v3" # Or other appropriate size

   # OCI
   compute_shape = "VM.Standard.E3.Flex"
   shape_config {
     ocpus = 2
     memory_in_gbs = 4
   }
   ```

2. Consider enabling additional features:
   - Advanced monitoring
   - Geo-redundant storage
   - Larger database instances
   - High-availability configurations
