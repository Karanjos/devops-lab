output "vnet_id" {
  value = module.network.vnet_id
}

output "subnet_id" {
  value = module.network.subnet_id
}

output "vm_name" {
  value = module.vm.vm_name
}

output "vm_private_ip" {
  value = module.vm.private_ip
}

output "vm_public_ip" {
  value = module.vm.public_ip
}

output "jenkins_vm_name" {
  value = module.jenkins_vm.vm_name
}

output "jenkins_vm_private_ip" {
  value = module.jenkins_vm.private_ip
}

output "jenkins_vm_public_ip" {
  value = module.jenkins_vm.public_ip
}

output "container_registry_name" {
  value = module.registry.container_registry_name
}