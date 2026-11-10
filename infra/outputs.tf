output "service_url" {
  description = "HTTPS URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.api.uri
}

output "artifact_registry" {
  description = "Docker repository the API image is pushed to."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}
