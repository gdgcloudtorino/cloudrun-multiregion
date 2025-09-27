
variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}
variable "gcs_bucket" {
  description = "The GCS Bucket"
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "multi-region-api"
}

variable "gcs_proxy_service_name" {
  description = "The name of the GCS proxy service."
  type        = string
  default     = "gcs-proxy"
}

variable "region_1" {
  description = "The first region for the Cloud Run service."
  type        = string
  default     = "europe-west8"
}

variable "region_2" {
  description = "The second region for the Cloud Run service."
  type        = string
  default     = "us-central1"
}
variable "artifact_registry_name" {
    default = "cloud-run-source-deploy"
  
}
variable "artifact_registry_location" {
  description = "Location for the artifact registry"
  default     = "europe-west8"
}
/*
variable "gemini_api_key" {
  description = "The API key for the Gemini API."
  type        = string
  sensitive   = true
}
*/