### Private Service Connect

resource "google_compute_service_attachment" "self" {
  name        = "${var.name}-psc-${random_id.tf_prefix.hex}"
  description = "A service attachment to expose the internal load balancer for Private Service Connect"

  # the region has to the same as the consumer due to GCP limitation
  region = var.region

  # optional, e.g., gitlab.internal.company.com
  domain_names = [var.domain_root]

  enable_proxy_protocol = false
  # a psc subnet, or with a `purpose=PRIVATE_SERVICE_CONNECT` `google_compute_subnetwork` in Terraform
  nat_subnets = [google_compute_subnetwork.psc.id]

  # an upstream forwarding rule to one of the following
  #
  # - regional internal proxy Network Load Balancer, google_compute_region_target_tcp_proxy
  #   with an INTERNAL_MANAGED load balancing scheme in the backend service
  # - regional internal Application Load Balancer, google_compute_region_target_http_proxy, google_compute_region_target_https_proxy, 
  #   with a INTERNAL_MANAGED load balancing scheme in the backend service
  # - internal passthrough Network Load Balancer,
  #   with an INTERNAL load balancing scheme in the backend service
  #
  # how to decide?
  #
  # - if the target deployment (MIG or NEG) does not terminate TLS, you should use an internal Application Load Balancer with TLS certificate configured
  # - if the target deployment (MIG or NEG) terminates TLS, you should use an internal passthrough Network Load Balancer on port 443
  #
  # notes in order to create an internal load balancer, GCP requires the creation of a proxy-only subnet within the network
  target_service = google_compute_forwarding_rule.https.self_link

  connection_preference = "ACCEPT_MANUAL"
  # a maps of "project_id" => { "id": "$project_id", "limit": $limit }
  dynamic "consumer_accept_lists" {
    iterator = each
    for_each = var.authorized_consumer_projects
    content {
      project_id_or_num = each.value["id"]
      connection_limit  = each.value["limit"]
    }
  }
}

### Compute - Network (psc subnet)

resource "google_compute_subnetwork" "psc" {
  name    = "${var.name}-psc-${random_id.tf_prefix.hex}"
  region  = var.region
  network = google_compute_network.self.id

  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = var.psc_subnetwork_cidr
}
