
# Get the project ID and region from the gcloud config
data "google_project" "project" {}

locals {
  project_id = data.google_project.project.project_id
  region     = "us-central1" # You can change this to your preferred region
}

# Enable necessary Google Cloud APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}



# Create a secret for the Gemini API key
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"
  project   = var.project_id

  replication {
    auto {
      
    }
  }
}

# The Cloud Run service that runs the game API
resource "google_cloud_run_v2_service" "default" {
  name     = "game-api"
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = "gcr.io/${var.project_id}/game-api:latest"

      env {
        name  = "DB_USER"
        value = google_sql_user.default.name
      }
      env {
        name  = "DB_NAME"
        value = google_sql_database.default.name
      }
      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.default.connection_name}"
      }
      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_api_key.secret_id
            version = "latest"
          }
        }
      }
    }

    # Mount the Cloud SQL instance
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.default.connection_name]
      }
    }
  }

  depends_on = [google_project_service.apis]
}

# Grant the Cloud Run service account access to the Cloud SQL instance
resource "google_project_iam_member" "sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_cloud_run_v2_service.default.service_account}"
}

# Grant the Cloud Run service account access to the secrets
resource "google_secret_manager_secret_iam_member" "db_password_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_cloud_run_v2_service.default.service_account}"
}

resource "google_secret_manager_secret_iam_member" "gemini_key_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gemini_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_cloud_run_v2_service.default.service_account}"
}

# Make the Cloud Run service publicly accessible
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the URL of the Cloud Run service
output "service_url" {
  description = "The URL of the game-api service."
  value       = google_cloud_run_v2_service.default.uri
}
