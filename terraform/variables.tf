variable "project_id" {
  default = "urban-take-home-test"
}
variable "region" {
  default = "europe-west1"
}

variable "environment" {
  default = "dev"
}

variable "cluster_version" {
  default = "1.18.12-gke.1210"
}

variable "node_count" {
  default = 1
}

variable "node_machine_type" {
  default = "n1-standard-1"
}

variable "node_disk_size" {
  default = 10
}

variable "node_disk_type" {
  default = "pd-standard"
}

variable "node_image_type" {
  default = "COS"
}

variable "node_preemptible" {
  default = false
}

variable "node_locations" {
  default = ["europe-west1-b"]
}
