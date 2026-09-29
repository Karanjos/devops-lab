output "repository_url" {
  description = "Prefix to use when tagging images, e.g. docker tag myimage <this>/backend:v1"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}
