
output "load_balancer_ip" {
  description = "The public IP address of the global load balancer."
  value       = google_compute_global_address.default.address
}

output "app_region_us" {
  description = "The URL of the US Cloud Run service."
  value       = module.app_region_us.endpoint
}

output "app_region_eu" {
  description = "The URL of the EU Cloud Run service."
  value       = module.app_region_eu.endpoint
}

output "gcs_proxy_us" {
  description = "The URL of the US GCS proxy service."
  value       = module.gcs_proxy_us.endpoint
}

output "gcs_proxy_eu" {
  description = "The URL of the EU GCS proxy service."
  value       = module.gcs_proxy_eu.endpoint
}
