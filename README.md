# Cloud ELT Infrastructure

This repository provides Terraform configurations and automation scripts for deploying an ELT pipeline infrastructure on **OCI** and **Azure**. It includes:
- **Databricks** for data processing
- **Apache Airflow** or **Azure Data Factory** for workflow orchestration
- **Python ingestion scripts** for fetching data from external sources
- **dbt models** for transformation

## 📌 Repository Structure
```
/terraform
   ├── /modules
   │    ├── airflow/
   │    ├── data_factory/
   │    ├── databricks/
   │    ├── networking/
   │    ├── storage/
   │    └── compute/
   ├── /environments
   │    ├── oci/
   │    ├── azure/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
/ingestion
   ├── api_ingestion.py
   ├── requirements.txt
/dbt_project
   ├── dbt_project.yml
   ├── models/
/workflows
   ├── airflow_dag.py
   ├── data_factory_pipeline.json
README.md
```

## 🚀 Deployment Instructions

1. Clone the repository:
   ```sh
   git clone https://github.com/janahlin/cloud-elt-infra.git
   ```

2. Install Terraform and authenticate to your cloud provider.

3. Choose the deployment environment (OCI or Azure) and configure `terraform.tfvars`.

4. Apply Terraform:
   ```sh
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

5. Run ingestion scripts and dbt transformations as needed.

## 🔧 Configuration

Modify `terraform.tfvars` based on your cloud provider and ELT tool selection.

- To use **Airflow**, set `use_airflow = true`
- To use **Azure Data Factory**, set `use_airflow = false`

## 📜 License

This project is licensed under the MIT License.
