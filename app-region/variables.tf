variable "service_name" {
  description = "The name of the GCS proxy service."
  type        = string
  default     = "multi-region-api"
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
variable "failover" {
  default = "false"
  description = "Whether to enable failover to the second region."
  type = string
}
variable "artifact_name" {
  default = "cloud-run-source-deploy"
}

variable "artifact_registry_location" {
  description = "Location for the artifact registry"
  default = "europe-west8"
}
