
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
  gcs_bucket = var.gcs_bucket
}

module "gcs_proxy_us" {
  source     = "../gcs-proxy"
  project_id = var.project_id
  region     = var.region_2
  gcs_bucket = var.gcs_bucket
}
module "game_db" {
  source     = "../database"
  project_id = var.project_id
  region     = var.region_1
  region_us  = var.region_2
}

module "game_api_eu" {
  source                = "../game-api"
  project_id            = var.project_id
  region                = var.region_1
  db_password_secret_id = module.game_db.secret_db_password
  db_host               = module.game_db.db_host
  db_user               = module.game_db.db_user
  db_name               = module.game_db.db_name
}
module "game_api_us" {
  source                = "../game-api"
  project_id            = var.project_id
  region                = var.region_2
  db_password_secret_id = module.game_db.secret_db_password
  db_host               = module.game_db.db_host
  db_user               = module.game_db.db_user
  db_name               = module.game_db.db_name
}

# Create two serverless network endpoint groups (NEGs)
# one for each regional Cloud Run service
resource "google_compute_region_network_endpoint_group" "neg_1" {
  name                  = "multi-region-neg-1"
  region                = var.region_1
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.service_name
  }
}

resource "google_compute_region_network_endpoint_group" "neg_2" {
  name                  = "multi-region-neg-2"
  region                = var.region_2
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.service_name
  }
}
# Create a backend service that uses the serverless NEGs
resource "google_compute_backend_service" "app_region" {
  name                  = "multi-region-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN
  log_config {
    enable = true
  }
  backend {
    group = google_compute_region_network_endpoint_group.neg_1.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.neg_2.id
  }
}

resource "google_compute_region_network_endpoint_group" "gsc_proxy_neg_1" {
  name                  = "gcs-proxy-region-neg-1"
  region                = var.region_1
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.gcs_proxy_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "gsc_proxy_neg_2" {
  name                  = "gcs-proxy-region-neg-2"
  region                = var.region_2
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = var.gcs_proxy_service_name
  }
}


resource "google_compute_backend_service" "gsc_proxy" {
  name                  = "gcs-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN
  log_config {
    enable = true
  }
  backend {
    group = google_compute_region_network_endpoint_group.gsc_proxy_neg_1.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.gsc_proxy_neg_2.id
  }
}




resource "google_compute_region_network_endpoint_group" "game_api_eu" {
  name                  = "game-api-region-neg-1"
  region                = var.region_1
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = module.game_api_eu.name
  }
}

resource "google_compute_region_network_endpoint_group" "game_api_us" {
  name                  = "game-api-region-neg-2"
  region                = var.region_2
  network_endpoint_type = "SERVERLESS"
  project               = data.google_project.project.project_id
  cloud_run {
    service = module.game_api_us.name
  }
}
resource "google_compute_backend_service" "game_api_main" {
  name                  = "game-backend-primary-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN
  log_config {
    enable = true
  }
  backend {
    group = google_compute_region_network_endpoint_group.game_api_eu.id
  }
}

resource "google_compute_backend_service" "game_api" {
  name                  = "game-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  enable_cdn            = false # Set to true to enable Cloud CDN
  log_config {
    enable = true
  }
  backend {
    group = google_compute_region_network_endpoint_group.game_api_eu.id
  }

  backend {
    group = google_compute_region_network_endpoint_group.game_api_us.id
  }
}

# Nginx instance template for region 1
resource "google_compute_instance_template" "nginx_template_1" {
  name_prefix  = "nginx-template-1-v2-"
  machine_type = "e2-micro"
  region       = var.region_1

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    
    cat <<EOF | sudo tee /etc/nginx/sites-available/reverse-proxy
    server {
        listen 80;
        server_name _;

        location /nginx/api/games {
            proxy_pass ${module.game_api_eu.uri}/api/games;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }


        location /nginx/storage/ {
            proxy_pass ${module.gcs_proxy_eu.uri}/storage;
            proxy_set_header Host ${module.gcs_proxy_eu.uri};
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /nginx/ {
            proxy_pass ${module.app_region_eu.uri};
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        location /healthz {
            proxy_pass ${module.app_region_eu.uri}/healthz;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    EOF

    sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default
    sudo service nginx restart
  EOT
}

# Nginx instance template for region 2
resource "google_compute_instance_template" "nginx_template_2" {
  name_prefix  = "nginx-template-2-v2-"
  machine_type = "e2-micro"
  region       = var.region_2

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    
    cat <<EOF | sudo tee /etc/nginx/sites-available/reverse-proxy
    server {
        listen 80;
        server_name _;

        location /nginx/api/games/add {
            proxy_pass ${module.game_api_eu.uri}/api/games/add;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /nginx/api/games {
            proxy_pass ${module.game_api_us.uri}/api/games;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }


        location /nginx/storage/ {
            proxy_pass ${module.gcs_proxy_us.uri}/storage;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /nginx/ {
            proxy_pass ${module.app_region_us.uri};
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        location /healthz {
            proxy_pass ${module.app_region_us.uri}/healthz;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    EOF

    sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default
    sudo service nginx restart
  EOT
}

# Nginx managed instance group in region 1
resource "google_compute_region_instance_group_manager" "nginx_mig_1" {
  name               = "nginx-mig-1"
  base_instance_name = "nginx-1"
  region             = var.region_1
  named_port {
    name = "http"
    port = 80
  }
  target_size        = 1
  version {
    instance_template  = google_compute_instance_template.nginx_template_1.id
  }
}

# Nginx managed instance group in region 2
resource "google_compute_region_instance_group_manager" "nginx_mig_2" {
  name               = "nginx-mig-2"
  base_instance_name = "nginx-2"
  region             = var.region_2
  target_size        = 1
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template  = google_compute_instance_template.nginx_template_2.id
  }
}

# Firewall rule to allow health checks to Nginx instances
resource "google_compute_firewall" "allow_nginx_health_checks" {
  name    = "allow-nginx-health-checks"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["nginx"]
}

# Health check for the Nginx backend service
resource "google_compute_health_check" "nginx_health_check" {
  name                = "nginx-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/healthz"
  }
}

# Backend service for the Nginx instance groups
resource "google_compute_backend_service" "nginx_backend_service" {
  name                  = "nginx-backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.nginx_health_check.id]

  backend {
    group = google_compute_region_instance_group_manager.nginx_mig_1.instance_group
  }

  backend {
    group = google_compute_region_instance_group_manager.nginx_mig_2.instance_group
  }
}


# Create a URL map to route all incoming requests to the backend service
resource "google_compute_url_map" "default" {
  name            = "multi-region-url-map"
  default_service = google_compute_backend_service.app_region.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "multi-region-path-matcher"
  }

  path_matcher {
    name            = "multi-region-path-matcher"
    
    path_rule {
      paths   = ["/api/games/add"]
      service = google_compute_backend_service.game_api_main.id
    }
    path_rule {
      paths   = ["/api/games/*","/api/games"]
      service = google_compute_backend_service.game_api.id
    }
    path_rule {
      paths   = ["/storage/*",]
      service = google_compute_backend_service.gsc_proxy.id
    }
    path_rule {
      paths   = ["/api/region/*","/api/region"]
      service = google_compute_backend_service.app_region.id
    }
    path_rule {
      paths   = ["/nginx/*"]
      service = google_compute_backend_service.nginx_backend_service.id
    }
    default_service = google_compute_backend_service.app_region.id
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



# Build and push the db-importer container image
# resource "null_resource" "db_importer_image" {
#   triggers = {
#     main_py          = filemd5("../db-importer/main.py")
#     games_sql        = filemd5("../db-importer/games.sql")
#     dockerfile       = filemd5("../db-importer/Dockerfile")
#     requirements_txt = filemd5("../db-importer/requirements.txt")
#   }

#   provisioner "local-exec" {
#     command = "gcloud builds submit --project=${var.project_id} --tag ${var.artifact_registry_location}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/db-importer-job:latest ../db-importer"
#   }
# }

# Create a Cloud Run Job to import the database data
module "db_importer_job" {
  source                = "../db-importer-job"
  project_id            = var.project_id
  region                = var.region_1
  db_host               = module.game_db.db_host
  db_name               = module.game_db.db_name
  db_user               = module.game_db.db_user
  db_password_secret_id = module.game_db.secret_db_password

  # depends_on = [null_resource.db_importer_image]
}

output "db_importer_job_name" {
  description = "The name of the database importer job."
  value       = module.db_importer_job.job_name
}
