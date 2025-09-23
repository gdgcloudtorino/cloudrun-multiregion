#!/bin/bash
terraform destroy -var="project_id=$(gcloud config get-value project)" -var="gcs_bucket=$(gcloud config get-value project)"