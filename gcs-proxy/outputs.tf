output "endpoint" {
  value = google_cloud_run_v2_service.service.urls[0]
}

output "uri" {
  value = google_cloud_run_v2_service.service.uri
}
output "name" {
  value = google_cloud_run_v2_service.service.name
}