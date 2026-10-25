variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  description = "Name of the Artifact Registry repository, e.g. devops-lab."
  type        = string
  default     = "devops-lab"
}
