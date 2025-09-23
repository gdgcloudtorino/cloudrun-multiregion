#!/bin/bash
terraform init
terraform apply -var="project_id=$(gcloud config get-value project)" -var="gcs_bucket=$(gcloud config get-value project)" -auto-approve

# Get all output variables from Terraform
echo "Retrieving Terraform outputs..."
LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)
APP_REGION_US=$(terraform output -raw app_region_us)
APP_REGION_EU=$(terraform output -raw app_region_eu)
GCS_PROXY_US=$(terraform output -raw gcs_proxy_us)
GCS_PROXY_EU=$(terraform output -raw gcs_proxy_eu)

# Export the variables and save them to a .env file
echo "Exporting Terraform outputs to ../.env"
{
  echo "LOAD_BALANCER_IP=${LOAD_BALANCER_IP}"
  echo "APP_REGION_US=${APP_REGION_US}"
  echo "APP_REGION_EU=${APP_REGION_EU}"
  echo "GCS_PROXY_US=${GCS_PROXY_US}"
  echo "GCS_PROXY_EU=${GCS_PROXY_EU}"
} > ../.env

# Export for the current session
export LOAD_BALANCER_IP
export APP_REGION_US
export APP_REGION_EU
export GCS_PROXY_US
export GCS_PROXY_EU

echo "Terraform outputs have been saved to .env and exported."
