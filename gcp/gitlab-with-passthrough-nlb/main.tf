provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "random" {}

terraform {
  required_version = "> 1.2.3, < 2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
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

resource "google_compute_network" "self" {
  name                    = "${var.name}-network-${random_id.tf_prefix.hex}"
  project                 = data.google_project.self.project_id
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "self" {
  ip_cidr_range              = var.subnetwork_cidr
  name                       = "${var.name}-subnetwork-${random_id.tf_prefix.hex}"
  network                    = google_compute_network.self.self_link
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = data.google_project.self.project_id
  purpose                    = "PRIVATE"
  region                     = "us-central1"

  stack_type = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "proxy_only" {
  project       = data.google_project.self.project_id
  ip_cidr_range = var.proxy_only_subnetwork_cidr
  name          = "${var.name}-proxy-only-${random_id.tf_prefix.hex}"
  network       = google_compute_network.self.self_link
  purpose       = "REGIONAL_MANAGED_PROXY"
  region        = var.region
  role          = "ACTIVE"
}

resource "google_compute_firewall" "allow_health_check_iap" {
  name    = "${var.name}-allow-health-check-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = google_compute_network.self.self_link

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
}

resource "google_compute_firewall" "allow_proxies" {
  name    = "${var.name}-allow-proxies-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = google_compute_network.self.self_link

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
  network = google_compute_network.self.self_link

  direction = "INGRESS"
  priority  = 1000
  source_ranges = [
    var.subnetwork_cidr,
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
  network = google_compute_network.self.self_link

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

data "google_compute_image" "gitlab_ee" {
  name    = "gitlab-1692823601-16-3-0-ee-0"
  project = "gitlab-public"
}

resource "google_compute_instance" "self" {
  project = data.google_project.self.project_id
  name    = "${var.name}-${random_id.tf_prefix.hex}"
  zone    = var.zone

  machine_type = var.machine_type

  boot_disk {
    auto_delete = true

    initialize_params {
      image = data.google_compute_image.gitlab_ee.self_link
      size  = 120
      type  = "pd-ssd"
    }
  }

  metadata = {
    google-logging-enable    = "0"
    google-monitoring-enable = "0"
  }

  network_interface {
    network    = google_compute_network.self.self_link
    subnetwork = google_compute_subnetwork.self.self_link
  }

  service_account {
    email = google_service_account.self.email
    scopes = [
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  tags = var.network_tags
}

resource "google_service_account" "self" {
  project      = data.google_project.self.project_id
  account_id   = "${var.name}-vm-${random_id.tf_prefix.hex}"
  display_name = "For GitLab Compute Instance"
}

resource "google_project_iam_member" "self" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/pubsub.publisher",
  ])

  project = data.google_project.self.project_id
  member  = google_service_account.self.member
  role    = each.key
}

### Compute - Endpoints

resource "google_compute_network_endpoint_group" "self" {
  name       = "${var.name}-neg-${random_id.tf_prefix.hex}"
  project    = data.google_project.self.project_id
  network    = google_compute_network.self.self_link
  subnetwork = google_compute_subnetwork.self.self_link
  zone       = var.zone

  network_endpoint_type = "GCE_VM_IP"
}

resource "google_compute_network_endpoint" "self" {
  project                = data.google_project.self.project_id
  network_endpoint_group = google_compute_network_endpoint_group.self.name
  instance               = google_compute_instance.self.name
  ip_address             = google_compute_instance.self.network_interface[0].network_ip
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
    host         = var.domain
    proxy_header = "NONE"
    request_path = "/-/health"
  }

  log_config {
    enable = true
  }
}
