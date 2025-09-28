#!/bin/bash
source ../.env
terraform init
terraform apply -var="project_id=${PROJECT_ID}" -var="gcs_bucket=${PROJECT_ID}" -auto-approve

# Get all output variables from Terraform
echo "Retrieving Terraform outputs..."
LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)
APP_REGION_US=$(terraform output -raw app_region_us)
APP_REGION_EU=$(terraform output -raw app_region_eu)
GCS_PROXY_US=$(terraform output -raw gcs_proxy_us)
GCS_PROXY_EU=$(terraform output -raw gcs_proxy_eu)
GAME_US=$(terraform output -raw game_us)
GAME_EU=$(terraform output -raw game_eu)

# Export the variables and save them to a .env file
echo "Exporting Terraform outputs to ../.env"
{
  echo "export PROJECT_ID=${PROJECT_ID}"
  echo "export LOAD_BALANCER_IP=${LOAD_BALANCER_IP}"
  echo "export APP_REGION_US=${APP_REGION_US}"
  echo "export APP_REGION_EU=${APP_REGION_EU}"
  echo "export GCS_PROXY_US=${GCS_PROXY_US}"
  echo "export GCS_PROXY_EU=${GCS_PROXY_EU}"
  echo "export GAME_EU=${GAME_EU}"
  echo "export GAME_US=${GAME_US}"
} > ../.env

# Export for the current session
export LOAD_BALANCER_IP
export APP_REGION_US
export APP_REGION_EU
export GCS_PROXY_US
export GCS_PROXY_EU
export GAME_EU
export GAME_US

echo "Terraform outputs have been saved to .env and exported."
