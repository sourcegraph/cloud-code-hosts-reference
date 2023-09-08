### Variables

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "name" {
  default = "gitlab"
}

variable "domain" {
  default = "gitlab-private-gcp.sg.dev"
}

variable "domain_root" {
  default = "sg.dev."
}

variable "proxy_only_subnetwork_cidr" {
  default = "10.0.0.0/24"
}

variable "subnetwork_cidr" {
  default = "10.100.0.0/24"
}

variable "psc_subnetwork_cidr" {
  default = "10.101.0.0/24"
}

variable "machine_type" {
  default = "n1-standard-4"
}

variable "network_tags" {
  default = [
    "gitlab-ee",
  ]
}

variable "subnet_router_network_tags" {
  default = [
    "subnet-router",
  ]
}

variable "ts_auth_key" {
  default = ""
}

variable "tls_cert_path" {}

variable "tls_private_key_path" {}

variable "project_id" {}

variable "authorized_consumer_projects" {
  type = map(object(
    {
      id    = string
      limit = number
    }
  ))
}
