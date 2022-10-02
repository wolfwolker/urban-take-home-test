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
  ip_cidr_range = "10.10.0.0/16"
  secondary_ip_range {
    range_name    = "${local.prefix}-subnet-pods"
    ip_cidr_range = "10.11.0.0/16"
  }
  secondary_ip_range {
    range_name    = "${local.prefix}-subnet-services"
    ip_cidr_range = "10.12.0.0/16"
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
  # management {
  #   auto_repair  = true
  #   auto_upgrade = true
  # }
  release_channel = "RAPID"

  # cluster_autoscaling = false
  default_max_pods_per_node = 100

  node_pools = [{
    # max_pods_per_node = 40
    name                      = "basic-node-pool"
    machine_type              = "e2-medium"
    node_locations            = "${var.region}-b,${var.region}-c"
    min_count                 = 1
    max_count                 = 2
    autoscaling = true
    local_ssd_count           = 0
    spot                      = false
    disk_size_gb              = 80
    disk_type                 = "pd-standard"
    image_type                = "COS_CONTAINERD"
    enable_gcfs               = false
    enable_gvnic              = false
    auto_repair               = true
    auto_upgrade              = true
    # service_account           = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
    preemptible               = false
    initial_node_count        = 1
    node_count                = 1
  }]

  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  # triggers = {
  #   cluster_instance_ids = module.gke.cluster_instance_ids
  # }

  depends_on = [
    module.gke
  ]

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  # connection {
  #   host = element(aws_instance.cluster.*.public_ip, 0)
  # }

  # provisioner "remote-exec" {
  #   # Bootstrap script called with private_ip of each node in the clutser
  #   inline = [
  #     "bootstrap-cluster.sh ${join(" ", aws_instance.cluster.*.private_ip)}",
  #   ]
  # }
  provisioner "local-exec" {
    command = <<-EOT
# we assume we have locally kubectl installed and the argocd binary, a better solution would be to run a container with this stuff, locally or in gcp

# let's sleep a bit to wait for the cluster to be ready
sleep 30

# download cluster credentials
gcloud container clusters get-credentials "${module.gke.cluster_id}" --region "${var.region}"

# install argo after setup the kluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# forward a port to the svc
# kubectl port-forward svc/argocd-server -n argocd :443
# or create a slb
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# a bit more sleep, the secrets are not ready
sleep 30
# login to argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo
argocd login --insecure $(kubectl -n argocd get svc argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}") --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) 

# create a new project
argocd app create urban-take-home-test-node-app --insecure --kube-context $(kubectl config current-context) --repo https://github.com/wolfwolker/urban-take-home-test --path k8s --dest-server https://kubernetes.default.svc --dest-namespace default --sync-policy auto
EOT
  }
}