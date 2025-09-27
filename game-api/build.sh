#!/bin/bash

# Script per buildare e deployare l'applicazione proxy per GCS.

set -e

# --- CONFIGURAZIONE ---
PROJECT_ID=$(gcloud config get-value project)


SERVICE_NAME="game-api"



# Nome del repository in Artifact Registry
AR_REPO="cloud-run-source-deploy"
AR_LOCATION=${REGION}

# Nome completo dell'immagine container
IMAGE_NAME="${AR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:latest"

# --- SCRIPT ---

echo "--- Configurazione Game Api Demo ---"
echo "Project ID:     ${PROJECT_ID}"
echo "Service Name:   ${SERVICE_NAME}"
echo "-------------------------------------"
echo


# 1. BUILD: Costruisce l'immagine dalla cartella app-proxy
echo -e "\n--- Fase 1: Build dell'immagine container ---"
gcloud builds submit . --tag ${IMAGE_NAME}
echo "Build completata con successo: ${IMAGE_NAME}"