
# Get the project ID and region from the gcloud config
resource "google_service_account" "default" {
  project      = var.project_id
  account_id   = "${var.service_name}-sa-${var.region}"
  display_name = "DGame API Service Account"
}

# Grant the service account permission to access the database password
resource "google_secret_manager_secret_iam_member" "secret_accessor_db" {
  project   = var.project_id
  secret_id = var.db_password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.default.email}"
}
resource "google_secret_manager_secret_iam_member" "secret_accessor_gemini" {
  project   = var.project_id
  secret_id = var.gemini_api_key_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.default.email}"
}
# The Cloud Run service that runs the game API
resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  deletion_protection = false
  template {
    service_account = google_service_account.default.email
    containers {
      image = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${var.artifact_name}/${var.service_name}:latest"

      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_HOST"
        value = var.db_host
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
      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = var.gemini_api_key_secret_id
            version = "latest"
          }
        }
      }
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 1
        period_seconds = 3
        failure_threshold = 1
        tcp_socket {
          port = 8080
        }
      }
      liveness_probe {
        failure_threshold = 3
        period_seconds = 5
        http_get {
          path = "/healthz"
        }
      }
    }# end container
  }#end template
  depends_on = [ google_secret_manager_secret_iam_member.secret_accessor_db, google_secret_manager_secret_iam_member.secret_accessor_gemini ]
    
}# end service




# Make the Cloud Run service publicly accessible
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


