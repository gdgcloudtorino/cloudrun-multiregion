#!/bin/bash
terraform destroy -var="project_id=$(gcloud config get-value project)"