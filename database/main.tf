
# Create a Cloud SQL for PostgreSQL instance
resource "google_sql_database_instance" "default" {
  name             = var.database_name
  database_version = "POSTGRES_16"
  region           = var.region
  project          = var.project_id

  settings {
    tier = var.tier
    edition = "ENTERPRISE"
    enable_google_ml_integration = true
    database_flags {
      name = "cloudsql.enable_google_ml_integration"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "Allow all"
      }
    }
  }

  deletion_protection = false # Set to true for production environments
}

# Create a database within the Cloud SQL instance
resource "google_sql_database" "default" {
  name     = "games"
  instance = google_sql_database_instance.default.name
  project  = var.project_id
}

# Create a random password for the database user
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Create a user for the database
resource "google_sql_user" "default" {
  name     = "game_api_user"
  instance = google_sql_database_instance.default.name
  password = random_password.db_password.result
  project  = var.project_id
}

# Store the database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}
