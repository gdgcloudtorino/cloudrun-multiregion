#!/bin/bash
source ../.env
terraform destroy -var="project_id=${PROJECT_ID}" -var="gcs_bucket=${PROJECT_ID}"