
# Get the project ID and region from the gcloud config
data "google_project" "project" {}

# The Cloud Run service that runs the game API
resource "google_cloud_run_v2_service" "service" {
  name     = "game-api"
  location = var.region
  project  = var.project_id

  template {
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

    
}# end service




# Make the Cloud Run service publicly accessible
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


