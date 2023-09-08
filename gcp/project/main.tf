terraform {
  required_version = "> 1.2.3, < 2"
}

provider "google" {}

provider "random" {}

terraform {
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

locals {
  services = [
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "servicemanagement.googleapis.com",
    "networkmanagement.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iap.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "runtimeconfig.googleapis.com",
    "deploymentmanager.googleapis.com",
    "servicedirectory.googleapis.com",
  ]
}

variable "project_name" {
  default = "GitLab EE Private Deployment"
}

// e.g., folders/some-id
variable "project_folder" {
  type = string
}

variable "billing_account" {
  type = string
}

resource "random_id" "tf_prefix" {
  byte_length = 3
}

resource "google_project" "self" {
  project_id          = "gitlab-ee-${random_id.tf_prefix.hex}"
  name                = var.project_name
  folder_id           = var.project_folder
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "self" {
  for_each = toset(local.services)
  project  = google_project.self.project_id
  service  = each.key
}

output "project_id" {
  value = google_project.self.project_id
}
