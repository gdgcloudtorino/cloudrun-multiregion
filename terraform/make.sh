#!/bin/bash
terraform init
terraform apply -var="project_id=$(gcloud config get-value project)"