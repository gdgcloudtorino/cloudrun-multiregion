resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  scaling {
    max_instance_count = 2
  }

  template {
    containers {
      image = "${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${var.artifact_name}/${var.service_name}:latest"
    env {
      name = "REGION"
      value = var.region
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
        http_get {
          path = "/healthz"
        }
      }
    }
  }
}