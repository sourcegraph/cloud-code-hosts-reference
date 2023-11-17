### Variables

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^([a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$", var.project_id))
    error_message = "must be a valid project name"
  }
}

variable "network_id" {
  validation {
    condition     = can(regex("^([a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$", var.network_id))
    error_message = "must be a valid network name"
  }
}

variable "compute_instance_name" {
  type = string
  validation {
    condition     = can(regex("^([a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$", var.compute_instance_name))
    error_message = "must be a valid instance name"
  }
}

variable "compute_instance_ip_address" {
  type = string
}

variable "compute_instance_network_tags" {
  type = list(string)
}

variable "compute_instance_subnetwork" {
  type        = string
  description = "the subnetwork the instance is in"
  validation {
    condition     = can(regex("^([a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$", var.compute_instance_subnetwork))
    error_message = "must be a valid subnetwork name"
  }
}


variable "name" {
  default = "sourcegraph-psc"
}

variable "healthcheck-https-path" {
  default = "/status"
}

variable "domain" {
  type    = string
  default = null
}

variable "domain_root" {
  default = "sg.dev."
}

variable "proxy_only_subnetwork_cidr" {
  default     = "10.0.0.0/24"
  description = "the cidr block for the regional managed proxy subnet"
}


variable "psc_subnetwork_cidr" {
  default = "10.101.0.0/24"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.psc_subnetwork_cidr))
    error_message = "The subnetwork_cidr must be a valid CIDR block."
  }
}

variable "network_tags" {
  default = [
    "sourcegraph-psc",
  ]
}

variable "subnet_router_network_tags" {
  default = [
    "sourcegraph-psc",
  ]
}


variable "authorized_consumer_projects" {
  type = map(object(
    {
      id    = string
      limit = number
    }
  ))
}
