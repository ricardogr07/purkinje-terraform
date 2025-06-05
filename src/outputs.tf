output "instance_name" {
  value = google_compute_instance.purkinje_vm.name
}

output "external_ip" {
  value = google_compute_instance.purkinje_vm.network_interface[0].access_config[0].nat_ip
}
