#!/bin/bash

# --- CONFIGURATION ---
# Service names and regions
APP_REGION_SERVICE_NAME="multi-region-api"
APP_REGION_1="europe-west8"
APP_REGION_2="us-central1"

# TODO: Replace with your gcs-proxy service name and region
GCS_PROXY_SERVICE_NAME="your-gcs-proxy-service-name"
GCS_PROXY_REGION="your-gcs-proxy-region"


# --- DYNAMICALLY GET SERVICE URLS ---
echo "--- Getting service URLs ---"
APP_REGION_URL_1=$(gcloud run services describe ${APP_REGION_SERVICE_NAME} --platform managed --region ${APP_REGION_1} --format 'value(status.url)')/api/region
APP_REGION_URL_2=$(gcloud run services describe ${APP_REGION_SERVICE_NAME} --platform managed --region ${APP_REGION_2} --format 'value(status.url)')/api/region

if [ "${GCS_PROXY_SERVICE_NAME}" != "your-gcs-proxy-service-name" ] && [ "${GCS_PROXY_REGION}" != "your-gcs-proxy-region" ]; then
    GCS_PROXY_URL=$(gcloud run services describe ${GCS_PROXY_SERVICE_NAME} --platform managed --region ${GCS_PROXY_REGION} --format 'value(status.url)')
else
    GCS_PROXY_URL="https://your-gcs-proxy-service-url"
fi
echo "--------------------------"
echo

# --- FUNCTIONS ---

# Function to invoke a URL and measure execution time
invoke_service() {
  URL=$1
  SERVICE_NAME=$2

  echo "--- Invoking ${SERVICE_NAME} ---"
  echo "URL: ${URL}"

  # Get the start time
  START_TIME=$(date +%s.%N)

  # Invoke the service using curl
  RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "${URL}")

  # Get the end time
  END_TIME=$(date +%s.%N)

  # Calculate the execution time using awk
  EXECUTION_TIME=$(echo "${END_TIME} ${START_TIME}" | awk '{printf "%.9f", $1 - $2}')

  # Extract the body and HTTP code
  BODY=$(echo "${RESPONSE}" | sed '$d')
  HTTP_CODE=$(echo "${RESPONSE}" | tail -n1 | cut -d: -f2)

  # Print the results
  echo "Response Body: ${BODY}"
  echo "HTTP Status Code: ${HTTP_CODE}"
  echo "Execution Time: ${EXECUTION_TIME} seconds"
  echo "-------------------------------------"
  echo
}

# --- SCRIPT ---

echo "--- Service Invocation Test Script ---"

# Invoke app-region service in region 1
invoke_service "${APP_REGION_URL_1}" "app-region (${APP_REGION_1})"

# Invoke app-region service in region 2
invoke_service "${APP_REGION_URL_2}" "app-region (${APP_REGION_2})"

# Invoke gcs-proxy service
if [ "${GCS_PROXY_URL}" != "https://your-gcs-proxy-service-url" ]; then
  invoke_service "${GCS_PROXY_URL}" "gcs-proxy"
else
  echo "--- Skipping gcs-proxy ---"
  echo "Please replace 'your-gcs-proxy-service-name' and 'your-gcs-proxy-region' in this script."
  echo "-------------------------------------"
fi

echo "--- Test Complete ---"
