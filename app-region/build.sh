#!/bin/bash

# Script per buildare e deployare un'applicazione su due regioni Cloud Run.
#
# Utilizzo:
# 1. Assicurati di aver installato gcloud CLI e di esserti autenticato.
# 2. Sostituisci [YOUR_PROJECT_ID] con il tuo ID progetto Google Cloud.
# 3. Esegui lo script dalla root del progetto: ./deploy.sh

# Interrompe lo script in caso di errore
set -e

# --- CONFIGURAZIONE ---
# Sostituisci con il tuo Project ID
PROJECT_ID=$(gcloud config get project)

# Nome del servizio Cloud Run (sarà lo stesso in entrambe le regioni)
SERVICE_NAME="multi-region-api"


# Nome del repository in Artifact Registry
AR_REPO="cloud-run-source-deploy"

# Il repository di Artifact Registry deve essere creato in una regione specifica.
# Usiamo REGION_1 come riferimento, ma è accessibile globalmente.
AR_LOCATION="europe-west8" # Esempio: Milano

# Nome completo dell'immagine container
IMAGE_NAME="${AR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:latest"

# --- SCRIPT ---

echo "--- Configurazione ---"
echo "Project ID:     ${PROJECT_ID}"
echo "Service Name:   ${SERVICE_NAME}"
echo "Image:          ${IMAGE_NAME}"
echo "----------------------"
echo



# Abilita le API necessarie (l'operazione viene saltata se sono già attive)
echo "Abilitazione API necessarie (run, cloudbuild, artifactregistry)..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

# Crea il repository Artifact Registry se non esiste
echo "Verifica del repository Artifact Registry..."
if ! gcloud artifacts repositories describe ${AR_REPO} --location=${AR_LOCATION} &>/dev/null; then
  echo "Repository '${AR_REPO}' non trovato. Creazione in corso in ${AR_LOCATION}..."
  gcloud artifacts repositories create ${AR_REPO} \
    --repository-format=docker \
    --location=${AR_LOCATION} \
    --description="Repository per immagini Cloud Run"
else
  echo "Repository '${AR_REPO}' già esistente."
fi

# 1. BUILD: Costruisce l'immagine con Cloud Build e la pusha su Artifact Registry
echo -e "\n--- Fase 1: Build dell'immagine container ---"
gcloud builds submit . --tag ${IMAGE_NAME}
echo "Build completata con successo: ${IMAGE_NAME}"

