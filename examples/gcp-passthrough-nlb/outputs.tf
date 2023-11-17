output "subnetwork_name" {
  value = data.google_compute_subnetwork.ghe.name
}

output "instance_ip_address" {
  value = data.google_compute_instance.ghe.network_interface[0].network_ip
}

output "instance_name" {
  value = data.google_compute_instance.ghe.name
}

output "service_attachment_uri" {
  value = module.sourcegraph-psc.service_attachment_uri
}
