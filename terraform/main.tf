module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 12.0"

  project_id        = "PROJECT_ID"
  name              = "CLUSTER_NAME"
  region            = "COMPUTE_REGION"
  network           = "NETWORK_NAME"
  subnetwork        = "SUBNET_NAME"
  ip_range_pods     = "SECONDARY_RANGE_PODS"
  ip_range_services = "SECONDARY_RANGE_SERVICES"
}