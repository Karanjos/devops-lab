output "jenkins_vm_ip" {
  value = module.vm.external_ip
}

output "jenkins_vm_name" {
  value = module.vm.instance_name
}

output "vm_service_account" {
  value = module.vm.service_account_email
}

output "artifact_registry_url" {
  value = module.registry.repository_url
}

output "network_name" {
  value = module.network.network_name
}
