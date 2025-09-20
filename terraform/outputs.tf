
output "load_balancer_ip" {
  description = "The public IP address of the global load balancer."
  value       = google_compute_global_address.default.address
}
