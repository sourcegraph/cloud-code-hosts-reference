### Load Balancer - Backend

resource "google_compute_region_backend_service" "self" {
  name    = "${var.name}-backend-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  region  = var.region

  connection_draining_timeout_sec = 300
  health_checks                   = [google_compute_region_health_check.self.self_link]
  load_balancing_scheme           = "INTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"

  log_config {
    enable      = true
    sample_rate = 1
  }

  backend {
    group           = google_compute_network_endpoint_group.self.self_link
    balancing_mode  = "RATE"
    max_rate        = 2147483647
    capacity_scaler = 1.0
  }

  port_name        = "http"
  protocol         = "HTTP"
  session_affinity = "NONE"
  timeout_sec      = 30
}

### Load Balancer - Frontend (https)

resource "google_compute_forwarding_rule" "https" {
  project = data.google_project.self.project_id
  region  = var.region
  name    = "${var.name}-forwarding-rule-${random_id.tf_prefix.hex}"

  network    = google_compute_network.self.self_link
  subnetwork = google_compute_subnetwork.self.self_link

  network_tier          = "PREMIUM"
  port_range            = "443-443"
  allow_global_access   = true
  ip_address            = google_compute_address.self.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  target                = google_compute_region_target_https_proxy.https.self_link

  depends_on = [
    google_compute_subnetwork.proxy_only,
  ]
}

resource "google_compute_address" "self" {
  project = data.google_project.self.project_id
  region  = var.region
  name    = "${var.name}-ingress-ip-${random_id.tf_prefix.hex}"

  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.self.self_link
}

resource "google_compute_region_url_map" "https" {
  name    = "${var.name}-url-map-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  region  = var.region

  default_service = google_compute_region_backend_service.self.self_link

  host_rule {
    hosts        = [var.domain]
    path_matcher = "path-matcher-1"
  }

  path_matcher {
    default_service = google_compute_region_backend_service.self.self_link
    name            = "path-matcher-1"

    path_rule {
      paths   = ["/"]
      service = google_compute_region_backend_service.self.self_link
    }
  }
}

resource "google_compute_region_target_https_proxy" "https" {
  name    = "${var.name}-target-https-proxy-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  region  = var.region

  ssl_certificates = [google_compute_region_ssl_certificate.self.self_link]
  url_map          = google_compute_region_url_map.https.self_link
}

resource "google_compute_region_ssl_certificate" "self" {
  name_prefix = "${var.name}-${random_id.tf_prefix.hex}"
  project     = data.google_project.self.project_id
  region      = var.region

  certificate = file(var.tls_cert_path)
  private_key = file(var.tls_private_key_path)
}
