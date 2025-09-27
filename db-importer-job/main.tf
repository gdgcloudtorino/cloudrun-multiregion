
# Create a service account for the Cloud Run Job
resource "google_service_account" "default" {
  project      = var.project_id
  account_id   = "db-importer-sa"
  display_name = "Database Importer Service Account"
}

# Grant the service account permission to access the database password
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  project   = var.project_id
  secret_id = var.db_password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.default.email}"
}

# Create a Cloud Run Job
resource "google_cloud_run_v2_job" "default" {
  name     = var.job_name
  project  = var.project_id
  location = var.region
  deletion_protection = false
  template {
    template {
      service_account = google_service_account.default.email

      containers {
        image = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/db-importer-job:latest"
        env {
          name  = "DB_HOST"
          value = var.db_host
        }
        env {
          name  = "DB_NAME"
          value = var.db_name
        }
        env {
          name  = "DB_USER"
          value = var.db_user
        }
        env {
          name = "DB_PASS"
          value_source {
            secret_key_ref {
              secret  = var.db_password_secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }
  
}
