output "endpoint" {
  value = google_cloud_run_v2_service.service.urls[0]
}