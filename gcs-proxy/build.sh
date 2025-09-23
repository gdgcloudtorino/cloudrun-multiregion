#!/bin/bash

# Script per buildare e deployare l'applicazione proxy per GCS.

set -e

# --- CONFIGURAZIONE ---
PROJECT_ID=$(gcloud config get-value project)

# Nome del servizio per la demo del proxy
SERVICE_NAME="gcs-proxy"

# Regione per il deploy (puoi scegliere quella che preferisci)
REGION="europe-west8"
REGION_2="us-central1"  # Esempio: Iowa
# !! IMPORTANTE !! Sostituisci con il nome del tuo bucket GCS privato.
GCS_BUCKET_NAME=$(gcloud config get-value project)

# Nome del repository in Artifact Registry
AR_REPO="cloud-run-source-deploy"
AR_LOCATION=${REGION}

# Nome completo dell'immagine container
IMAGE_NAME="${AR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:latest"

# --- SCRIPT ---

echo "--- Configurazione GCS Proxy Demo ---"
echo "Project ID:     ${PROJECT_ID}"
echo "Service Name:   ${SERVICE_NAME}"
echo "Bucket GCS:     ${GCS_BUCKET_NAME}"
echo "-------------------------------------"
echo

if [ "$GCS_BUCKET_NAME" == "[YOUR_BUCKET_NAME]" ]; then
    echo "ERRORE: Per favore, modifica lo script e imposta la variabile GCS_BUCKET_NAME."
    exit 1
fi

# 1. BUILD: Costruisce l'immagine dalla cartella app-proxy
echo -e "\n--- Fase 1: Build dell'immagine container ---"
gcloud builds submit . --tag ${IMAGE_NAME}
echo "Build completata con successo: ${IMAGE_NAME}"
