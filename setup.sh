#!/bin/bash
PROJECT_ID=$(gcloud config get-value project)
echo "export PROJECT_ID=${PROJECT_ID}" > .env