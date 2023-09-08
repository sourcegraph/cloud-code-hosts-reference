### (Optional) - Tailscale Subnet Router
###
### This is used to access the private GitLab instance from local machine
### over Tailscale, i.e., the VPN. 
### The purpose is to simulate how customer users would interact with the 
### private GitLab instance on a daily basis.
### It does not contribute to the PSC connection between customer GitLab
### and Sourcegraph Cloud instance in any way.

resource "google_compute_instance" "subnet_router" {
  count = var.ts_auth_key != "" ? 1 : 0

  project      = data.google_project.self.project_id
  name         = "${var.name}-exit-gateway-${random_id.tf_prefix.hex}"
  zone         = var.zone
  machine_type = "e2-small"
  network_interface {
    network    = google_compute_network.self.self_link
    subnetwork = google_compute_subnetwork.self.self_link
    access_config {
      // allow public internet access
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  # we should use a different GSA here, but I am lazy
  # and this is for demo only
  service_account {
    email = google_service_account.self.email
    scopes = [
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  tags = var.subnet_router_network_tags

  metadata_startup_script = <<-EOF
#!/bin/bash
set -euxo pipefail

curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

tailscale up --authkey=${var.ts_auth_key} --advertise-routes=${var.subnetwork_cidr} --accept-dns=false
tailscale set --ssh
EOF
}

resource "google_compute_firewall" "allow_subnet_router_ingress" {
  name    = "${var.name}-allow-subner-router-${random_id.tf_prefix.hex}"
  project = data.google_project.self.project_id
  network = google_compute_network.self.self_link

  direction = "INGRESS"
  source_ranges = [
    "0.0.0.0/0",
  ]
  target_tags = var.subnet_router_network_tags

  priority = 1000

  allow {
    protocol = "udp"
    ports    = ["41641"]
  }
}
