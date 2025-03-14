# Cloud ELT Infrastructure

This repository provides a **Terraform-based infrastructure** for **OCI and Azure**, allowing deployment of:

✅ **Databricks** (Optional)  
✅ **Airflow on OCI** (Optional)  
✅ **Azure Data Factory** (Optional)  

## Usage
### Initialize Terraform
```
terraform init
```

### Deploy to OCI with Databricks & Airflow
```
terraform apply -var="cloud_provider=oci" -var="enable_databricks=true" -var="enable_airflow=true" -var="enable_data_factory=false" -auto-approve
```

### Deploy to Azure with Databricks & Data Factory
```
terraform apply -var="cloud_provider=azure" -var="enable_databricks=true" -var="enable_airflow=false" -var="enable_data_factory=true" -auto-approve
```

## Structure
- `terraform/oci/` - Terraform configs for OCI (Airflow, Databricks)
- `terraform/azure/` - Terraform configs for Azure (Data Factory, Databricks)
- `ingestion/` - Python scripts for API data ingestion
- `dbt_project/` - dbt transformations
- `workflows/` - Airflow DAGs or Azure Data Factory pipelines

