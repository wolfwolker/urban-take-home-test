provider "google" {
  project     = var.project_id
  region      = var.region
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  prefix = "${var.project_id}-${var.environment}"
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = "false"

}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${local.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
  secondary_ip_range {
    range_name    = "${local.prefix}-subnet-pods"
    ip_cidr_range = "192.168.10.0/24"
  }
  secondary_ip_range {
    range_name    = "${local.prefix}-subnet-services"
    ip_cidr_range = "192.169.10.0/24"
  }

}


module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"

  project_id        = var.project_id
  name              = "${local.prefix}-cluster"
  region            = var.region
  zones = ["${var.region}-b", "${var.region}-c"]
  network           = google_compute_network.vpc.name
  subnetwork        = google_compute_subnetwork.subnet.name
  ip_range_pods     = "${local.prefix}-subnet-pods"
  ip_range_services = "${local.prefix}-subnet-services"
  depends_on = [
    google_compute_subnetwork.subnet
  ]
}