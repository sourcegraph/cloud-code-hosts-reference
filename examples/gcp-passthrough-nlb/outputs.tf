output "subnetwork_name" {
  value = data.google_compute_subnetwork.ghe.name
}

output "instance_name" {
  value = data.google_compute_instance.ghe.id
}
output "instance_ip_address" {
  value = data.google_compute_instance.ghe.network_interface[0].network_ip
}

output "instance_name" {
  value = data.google_compute_instance.self.name
}

output "service_attachment_uri" {
  value = google_compute_service_attachment.self.id
}
