provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}


terraform {
  required_version = "> 1.2.3, < 2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.79.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

data "google_project" "self" {
  project_id = var.project_id
}



resource "random_id" "tf_prefix" {
  byte_length = 3
}

### Compute - Network

data "google_compute_network" "self" {
  name = var.network_id
}

# @michaellzc we also need the subnetwork the instance already exists in

data "google_compute_subnetwork" "self" {
  name = var.compute_instance_subnetwork
}

resource "google_compute_subnetwork" "proxy_only" {
  project       = data.google_project.self.project_id
  ip_cidr_range = var.proxy_only_subnetwork_cidr
  name          = "${var.name}-proxy-only-${random_id.tf_prefix.hex}"
  network       = data.google_compute_network.self.self_link
  purpose       = "REGIONAL_MANAGED_PROXY"
  region        = var.region
  role          = "ACTIVE"
}


resource "google_compute_firewall" "allow_health_check_iap" {
  name    = "${var.name}-allow-health-check-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = data.google_compute_network.self.self_link

  direction = "INGRESS"
  source_ranges = [
    "130.211.0.0/22",  # internal alb health check, https://cloud.google.com/load-balancing/docs/health-checks#fw-rule
    "35.191.0.0/16",   # internal alb health check, https://cloud.google.com/load-balancing/docs/health-checks#fw-rule
    "35.235.240.0/20", # iap, https://cloud.google.com/iap/docs/using-tcp-forwarding
  ]

  priority = 1000

  allow {
    protocol = "all"
  }
  description = "allow health check and iap for sourcegraph psc"
}

resource "google_compute_firewall" "allow_proxies" {
  name    = "${var.name}-allow-proxies-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = data.google_compute_network.self.self_link

  direction = "INGRESS"
  priority  = 1000
  source_ranges = [
    var.proxy_only_subnetwork_cidr,
  ]
  target_tags = var.network_tags

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "allow_subnet" {
  name    = "${var.name}-allow-subnet-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = data.google_compute_network.self.self_link

  direction = "INGRESS"
  priority  = 1000
  source_ranges = [
    data.google_compute_subnetwork.self.ip_cidr_range
  ]
  target_tags = var.network_tags

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
}

# allow traffic from the psc subnet, i.e., the consumer
resource "google_compute_firewall" "allow_psc" {
  name    = "${var.name}-allow-psc-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = data.google_compute_network.self.self_link

  direction = "INGRESS"
  priority  = 1000
  source_ranges = [
    var.psc_subnetwork_cidr
  ]
  target_tags = var.network_tags

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
}

### Compute - Instance

data "google_compute_instance" "self" {
  name    = var.compute_instance_name
  project = data.google_project.self.project_id
  zone    = var.zone
}

### Compute - Endpoints

resource "google_compute_network_endpoint_group" "self" {
  name       = "${var.name}-neg-${random_id.tf_prefix.hex}"
  project    = data.google_project.self.project_id
  network    = data.google_compute_network.self.self_link
  subnetwork = data.google_compute_subnetwork.self.self_link
  zone       = var.zone

  network_endpoint_type = "GCE_VM_IP"
}

resource "google_compute_network_endpoint" "self" {
  project                = data.google_project.self.project_id
  network_endpoint_group = google_compute_network_endpoint_group.self.name
  instance               = data.google_compute_instance.self.name
  ip_address             = data.google_compute_instance.self.network_interface[0].network_ip
}

resource "google_compute_region_health_check" "self" {
  name    = "${var.name}-health-check-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  region  = var.region

  check_interval_sec  = 5
  healthy_threshold   = 2
  timeout_sec         = 5
  unhealthy_threshold = 2

  https_health_check {
    proxy_header = "NONE"
    request_path = var.healthcheck_https_path
  }

  log_config {
    enable = true
  }
}
