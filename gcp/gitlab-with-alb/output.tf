### Output

output "instance_name" {
  value = google_compute_instance.self.name
}

output "service_attachment_uri" {
  value = google_compute_service_attachment.self.id
}
