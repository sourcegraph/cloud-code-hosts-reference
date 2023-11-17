### Load Balancer - Backend

resource "google_compute_region_backend_service" "self" {
  name    = "${var.name}-backend-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  region  = var.region

  connection_draining_timeout_sec = 60
  health_checks                   = [google_compute_region_health_check.self.self_link]
  load_balancing_scheme           = "INTERNAL"

  log_config {
    enable      = true
    sample_rate = 1
  }

  backend {
    group = google_compute_network_endpoint_group.self.self_link
  }

  protocol         = "TCP"
  session_affinity = "NONE"
  timeout_sec      = 30

}

### Load Balancer - Frontend (passthrough nlb)

resource "google_compute_forwarding_rule" "https" {
  project = data.google_project.self.project_id
  region  = var.region
  name    = "${var.name}-forwarding-rule-${random_id.tf_prefix.hex}"

  network    = data.google_compute_network.self.self_link
  subnetwork = data.google_compute_subnetwork.self.self_link

  network_tier          = "PREMIUM"
  ports                 = ["443"]
  allow_global_access   = true
  ip_address            = google_compute_address.self.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.self.self_link

  depends_on = [
    google_compute_subnetwork.proxy_only,
  ]
}

resource "google_compute_address" "self" {
  project = data.google_project.self.project_id
  region  = var.region
  name    = "${var.name}-ingress-ip-${random_id.tf_prefix.hex}"

  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.self.self_link
}
