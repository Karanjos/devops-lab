output "external_ip" {
  value = google_compute_address.static_ip.address
}

output "instance_name" {
  value = google_compute_instance.vm.name
}

output "service_account_email" {
  value = google_service_account.vm.email
}
