
output "job_name" {
  description = "The name of the created Cloud Run Job."
  value       = google_cloud_run_v2_job.default.name
}
