variable "name" {
  type = string
  description = "Name of the environment being protected. All resources will be prefixed with this name"
}

variable "project" {
  type = string
  description = "GCloud project name where AccessTier is deployed"
}

variable "region" {
  type = string
  description = "Region in which to create the Accestier"
}

variable "site_name" {
  type        = string
  description = "Name to use when registering this AccessTier with the console"
}

variable "refresh_token" {
  type        = string
  description = "API token generated from the Banyan console"
}

variable "site_domain_names" {
  type        = list(string)
  description = "List of aliases or CNAMEs that will direct traffic to this AccessTier"
}

variable "api_server" {
  type        = string
  description = "URL to the Banyan API server"
  default     = "https://net.banyanops.com/api/v1"
}

variable "cluster_name" {
  type        = string
  description = "Name of an existing Shield cluster to register this AccessTier with"
}

// might be added later
//variable "custom_user_data" {
//  type        = list(string)
//  description = "Custom commands to append to the startup script."
//  default     = []
//}

variable "redirect_http_to_https" {
  type        = bool
  description = "If true, requests to the AccessTier on port 80 will be redirected to port 443"
  default     = false
}

variable "machine_type" {
  type = string
  description = "Google compute instance types"
  default = "e2-standard-4"
}

variable "network" {
  type = string
  description = "Name of the network the AccessTier will belong to"
}

variable "subnetwork" {
  type = string
  description = "Name of the subnetwork the AccessTier will belong to"
}

variable "minimum_num_of_instances" {
  type = number
  description = "The minimum number of instances that should be running"
  default = 2
}

variable "deb_repo" {
  type = string
  description = "the repo holding the netagent binaries"
  default = "www.banyanops.com"
}

variable "at_version" {
  type = string
  description = "version specified to install if left blank, latest will be installed"
  default = ""
}

variable "datadog_api_key" {
    type = string
    description = "API key for DataDog"
    default = null
}