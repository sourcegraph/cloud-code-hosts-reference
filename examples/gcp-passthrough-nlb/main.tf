

data "google_client_config" "default" {}

provider "google" {}

data "google_compute_instance" "ghe" {
  project = var.project_name
  zone    = var.zone
  name    = var.instance_name
}

data "google_compute_subnetwork" "ghe" {
  project = var.project_name
  name    = var.subnet_name
  region  = var.region
}

module "sourcegraph-psc" {
  source = "../../modules/gcp-passthrough-nlb"

  project_id = "sourcegraph-github-enterprise"
  network_id = "ghe"

  region = "us-central1"
  zone   = "us-central1-a"

  compute_instance_name         = data.google_compute_instance.ghe.name
  compute_instance_ip_address   = data.google_compute_instance.ghe.network_interface[0].network_ip
  compute_instance_subnetwork   = data.google_compute_subnetwork.ghe.name
  compute_instance_network_tags = data.google_compute_instance.ghe.tags

  authorized_consumer_projects = {
    "src-cd795a54649fc24d9b5f" : {
      id : "src-cd795a54649fc24d9b5f",
      limit : 10,
    }
  }
}
