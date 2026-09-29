# Artifact Registry, NOT Container Registry (gcr.io), which is the legacy product Google is
# retiring in favor of this one. This creates a Docker-format repository your images push to
# as: <region>-docker.pkg.dev/<project_id>/<repository_id>/<image>:<tag>
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Images for the devops-lab project: backend, frontend, kafka-connect"
}
