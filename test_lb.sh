#!/bin/bash
source .env
# --- CONFIGURATION ---
# Service names and regions
APP_REGION_1="europe-west8"
APP_REGION_2="us-central1"

echo "--------------------------"

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
get_image() {
  URL=$1
  SERVICE_NAME=$2

  echo "--- Invoking ${SERVICE_NAME} ---"
  echo "URL: ${URL}"

  # Get the start time
  START_TIME=$(date +%s.%N)

  # Invoke the service using curl
  RESPONSE=$(curl -o test_1.jpeg -s -w "\nHTTP_CODE:%{http_code}" "${URL}")

  # Get the end time
  END_TIME=$(date +%s.%N)

  # Calculate the execution time using awk
  EXECUTION_TIME=$(echo "${END_TIME} ${START_TIME}" | awk '{printf "%.9f", $1 - $2}')

  # Extract the body and HTTP code
  #BODY=$(echo "${RESPONSE}" | sed '$d')
  HTTP_CODE=$(echo "${RESPONSE}" | tail -n1 | cut -d: -f2)

  # Print the results
  # maybe save the image locally
  echo "HTTP Status Code: ${HTTP_CODE}"
  echo "Execution Time: ${EXECUTION_TIME} seconds"
  echo "-------------------------------------"
  echo
}
# --- SCRIPT ---

echo "--- Service Invocation Test Script ---"


invoke_service "http://${LOAD_BALANCER_IP}/api/region" "Load Balancer"


# invoke with a load balancer
get_image "http://${LOAD_BALANCER_IP}/storage/test_1.jpeg" "app-region (${APP_REGION_2})"


invoke_service "http://${LOAD_BALANCER_IP}/api/games?q=Tigelle" "Load Balancer"


echo "--- Test Complete ---"
