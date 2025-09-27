
variable "job_name" {
  description = "The name of the Cloud Run Job."
  type        = string
  default     = "db-importer-job"
}

variable "project_id" {
  description = "The project ID to host the resources."
  type        = string
}

variable "region" {
  description = "The region for the Cloud Run Job."
  type        = string
}

variable "db_host" {
  description = "The host of the database to connect to."
  type        = string
}

variable "db_name" {
  description = "The name of the database to connect to."
  type        = string
}

variable "db_user" {
  description = "The user for the database connection."
  type        = string
}

variable "db_password_secret_id" {
  description = "The ID of the Secret Manager secret containing the database password."
  type        = string
}
variable "artifact_registry_name" {
  default = "cloud-run-source-deploy"
}
variable "artifact_registry_location" {
  description = "Location for the artifact registry"
  default     = "europe-west8"
}