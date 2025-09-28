variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}
variable "database_name" {
  type = string
  default = "game-db"
}
variable "region" {
  description = "The first region for the Cloud Run service."
  type        = string
  default     = "europe-west8"
}
variable "region_us" {
  description = "The first region for the Cloud Run service."
  type        = string
  default     = "us-east3"
}
variable "tier" {
  default = "db-f1-micro"
  type = string
  description = "The Cloud SQL Tier database"
}
