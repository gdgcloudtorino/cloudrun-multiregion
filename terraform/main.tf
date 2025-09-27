
# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
}

# Data source to get project details
data "google_project" "project" {}

# Reserve a global static IP address for the load balancer
resource "google_compute_global_address" "default" {
  name = "multi-region-lb-ip"
}

resource "google_apikeys_key" "gemini" {
  name         = "gemini-api-key"
  
  restrictions {
        # Example of whitelisting Maps Javascript API and Places API only
        api_targets {
            service = "generativelanguage.googleapis.com"
        }
  }
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

resource "google_secret_manager_secret_version" "gemini_api_key" {
  secret      = google_secret_manager_secret.gemini_api_key.id
  secret_data = google_apikeys_key.gemini.key_string
}

module "app_region_eu" {
  source     = "../app-region"
  project_id = var.project_id
  region     = var.region_1
}

module "app_region_us" {
  source     = "../app-region"
  project_id = var.project_id
  region     = var.region_2
}

module "gcs_proxy_eu" {
  source     = "../gcs-proxy"
  project_id = var.project_id
  region     = var.region_1
  gcs_bucket = "${var.gcs_bucket}"
}

module "gcs_proxy_us" {
  source     = "../gcs-proxy"
  project_id = var.project_id
  region     = var.region_2
  gcs_bucket = "${var.gcs_bucket}"
}
module "game_db" {
  source = "../database"
  project_id = var.project_id
  region     = var.region_1
}

module "game_api_eu" {
  source     = "../game-api"
  project_id = var.project_id
  region     = var.region_1
  db_password_secret_id = module.game_db.secret_db_password
  gemini_api_key_secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  db_host = module.game_db.db_host
  db_user =  module.game_db.db_user
  db_name = module.game_db.db_name
}

module "game_api_us" {
  source     = "../game-api"
  project_id = var.project_id
  region     = var.region_2
  db_password_secret_id = module.game_db.secret_db_password
  gemini_api_key_secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  db_host = module.game_db.db_host
  db_user =  module.game_db.db_user
  db_name = module.game_db.db_name
}

# Create two serverless network endpoint groups (NEGs)
# one for each regional Cloud Run service
resource "google_compute_region_network_endpoint_group" "neg_1" {
  name                  = "multi-region-neg-1"
  region                = var.region_1
  provider              = google-beta
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.service_name
  }
}

resource "google_compute_region_network_endpoint_group" "neg_2" {
  name                  = "multi-region-neg-2"
  region                = var.region_2
  provider              = google-beta
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.service_name
  }
}

resource "google_compute_region_network_endpoint_group" "gsc_proxy_neg_1" {
  name                  = "gcs-proxy-region-neg-1"
  region                = var.region_1
  provider              = google-beta
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.gcs_proxy_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "gsc_proxy_neg_2" {
  name                  = "gcs-proxy-region-neg-2"
  region                = var.region_2
  provider              = google-beta
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.gcs_proxy_service_name
  }
}

# Create a backend service that uses the serverless NEGs
resource "google_compute_backend_service" "app_region" {
  name                  = "multi-region-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN

  backend {
    group = google_compute_region_network_endpoint_group.neg_1.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.neg_2.id
  }
}
resource "google_compute_backend_service" "gsc_proxy" {
  name                  = "gcs-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN

  backend {
    group = google_compute_region_network_endpoint_group.gsc_proxy_neg_1.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.gsc_proxy_neg_2.id
  }
}

# Create a URL map to route all incoming requests to the backend service
resource "google_compute_url_map" "default" {
  name            = "multi-region-url-map"
  default_service = google_compute_backend_service.app_region.id
  host_rule {
    hosts       = ["*"]
    path_matcher = "multi-region-path-matcher"
  }
  path_matcher {
    name = "multi-region-path-matcher"
    default_service = google_compute_backend_service.app_region.id
    path_rule {
      paths = ["/api/region"]
      service = google_compute_backend_service.app_region.id
    }
    path_rule {
      paths = ["/storage/*"]
      service = google_compute_backend_service.gsc_proxy.id
    }
  }
}

# Create a target HTTP proxy to route requests to the URL map
resource "google_compute_target_http_proxy" "default" {
  name    = "multi-region-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Create a global forwarding rule to route incoming requests to the proxy
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "multi-region-forwarding-rule"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Grant the load balancer's service account permission to invoke the Cloud Run services
# This service account is automatically created by Google for the backend service
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Build and push the db-importer container image
resource "null_resource" "db_importer_image" {
  triggers = {
    main_py          = filemd5("../db-importer/main.py")
    games_sql        = filemd5("../db-importer/games.sql")
    dockerfile       = filemd5("../db-importer/Dockerfile")
    requirements_txt = filemd5("../db-importer/requirements.txt")
  }

  provisioner "local-exec" {
    command = "gcloud builds submit --project=${var.project_id} --tag gcr.io/${var.project_id}/db-importer-job:latest ../db-importer"
  }
}

# Create a Cloud Run Job to import the database data
module "db_importer_job" {
  source                = "../db-importer-job"
  project_id            = var.project_id
  region                = var.region_1
  db_host               = module.game_db.db_host
  db_name               = module.game_db.db_name
  db_user               = module.game_db.db_user
  db_password_secret_id = module.game_db.secret_db_password

  depends_on = [null_resource.db_importer_image]
}

output "db_importer_job_name" {
  description = "The name of the database importer job."
  value       = module.db_importer_job.job_name
}
