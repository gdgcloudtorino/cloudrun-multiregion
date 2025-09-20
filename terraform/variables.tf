
variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "multi-region-api"
}
variable "proxy_service_name" {
  description = "The name of the Cloud Run service."
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
