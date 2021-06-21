
provider "google" {
  project = "my-gcloud-project"
  region  = "us-west1"
}

variable "refresh_token" {
  type = string
}

module "gcp_accesstier" {
  source = "../"

  name                     = "my-accesstier"
  project                  = "my-project"
  region                   = "us-west1"
  network                  = "my-network"
  subnetwork               = "my-subnet"
  cluster_name             = "us-west1"
  site_name                = "my-banyan-site"
  site_domain_names        = ["*.bnndemos.com"]
  minimum_num_of_instances = 2
  refresh_token            = var.refresh_token
}
