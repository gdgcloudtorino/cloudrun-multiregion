# output the database host
output "db_host" {
  value = google_sql_database_instance.default.public_ip_address 
}

output "db_user" {
  value = google_sql_user.default.name
}

output "secret_db_password" {
  value = google_secret_manager_secret.db_password.id
}