# Cloud ELT Infrastructure

This repository provides Terraform configurations and automation scripts for deploying an ELT pipeline infrastructure on **OCI** and **Azure**. It includes:
- **Databricks** for data processing
- **Apache Airflow** (for OCI) or **Azure Data Factory** (for Azure) for workflow orchestration
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
   git clone https://github.com/YOUR_USERNAME/cloud-elt-infra.git
   ```

2. Install Terraform and authenticate to your cloud provider.

3. Run Terraform initialization:
   ```sh
   terraform init
   ```

4. Apply Terraform interactively:
   ```sh
   terraform apply
   ```
   You will be prompted to select:
   - **Cloud Provider** (`oci` or `azure`)
   - **Deployment Environment** (`dev`, `staging`, `production`)

5. The ELT tool is automatically chosen based on the cloud provider:
   - If **Azure** is selected → **Azure Data Factory** is used
   - If **OCI** is selected → **Apache Airflow** is used

6. Run ingestion scripts and dbt transformations as needed.

## 🔧 Configuration

Modify `terraform.tfvars` (optional) if you want to **predefine the values** instead of interactive input.

## 📜 License

This project is licensed under the MIT License.
