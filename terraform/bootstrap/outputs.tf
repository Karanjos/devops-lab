output "state_bucket_name" {
  description = "Put this into terraform/envs/dev/backend.tf as the 'bucket' value."
  value       = google_storage_bucket.tf_state.name
}
