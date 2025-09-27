
variable "service_name" {
  description = "The name of the GCS proxy service."
  type        = string
  default     = "game-api"
}
variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The first region for the Cloud Run service."
  type        = string
  default     = "europe-west8"
}

variable "artifact_name" {
  default = "cloud-run-source-deploy"
}

variable "artifact_registry_location" {
  description = "Location for the artifact registry"
  default = "europe-west8"
}
variable "gemini_api_key" {
  description = "The API key for the Gemini model."
  type        = string
  sensitive   = true
}
