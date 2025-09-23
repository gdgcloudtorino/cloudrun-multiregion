variable "service_name" {
  description = "The name of the GCS proxy service."
  type        = string
  default     = "gcs-proxy"
}
variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}
variable "gcs_bucket" {
  description = "The GCS Bucket"
  type        = string
}
variable "artifact_name" {
  default = "cloud-run-source-deploy"
}
variable "region" {
  description = "The first region for the Cloud Run service."
  type        = string
  default     = "europe-west8"
}


variable "artifact_registry_location" {
  description = "Location for the artifact registry"
  default = "europe-west8"
}
