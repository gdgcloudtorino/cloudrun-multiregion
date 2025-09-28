#!/bin/bash
PROJECT_ID=$(gcloud config get-value project)
echo "export PROJECT_ID=${PROJECT_ID}" > .env
cd app-region && ./build.sh
cd ../gcs-proxy && ./build.sh
cd ../game-api && ./build.sh
cd ../terraform && ./make.sh
cd ..
./test_services.sh