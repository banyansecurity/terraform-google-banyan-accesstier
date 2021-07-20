Banyan Google Cloud Access Tier Module
======================================

Creates an autoscaling Access Tier for use with [Banyan Security][banyan-security].

This module creates an autoscaler and a TCP load balancer in Google Cloud (GCP) for a Banyan Access Tier. Only the load balancer is exposed to the public internet. The Access Tier and your applications live in private subnets with no ingress from the internet.

## Usage

```hcl
provider "google" {
  project = "my-gcloud-project"
  region  = "us-west1"
}

module "gcp_accesstier" {
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
```

## Notes

It's probably also a good idea to leave the `refresh_token` out of your code and pass it as a variable instead, so you don't accidentally commit your Banyan API token to your version control system:

```hcl
variable "refresh_token" {
  type = string
}

module "gcp_accesstier" {
  source                 = "banyansecurity/banyan-accesstier/google"
  refresh_token          = var.refresh_token
  ...
}
```

```bash
export TF_VAR_refresh_token="eyJhbGciOiJSUzI1NiIsIm..."
terraform plan
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_server"></a> [api\_server](#input\_api\_server) | URL to the Banyan API server | `string` | `"https://net.banyanops.com/api/v1"` | no |
| <a name="input_at_version"></a> [at\_version](#input\_at\_version) | version specified to install if left blank, latest will be installed | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of an existing Shield cluster to register this AccessTier with | `string` | n/a | yes |
| <a name="input_deb_repo"></a> [deb\_repo](#input\_deb\_repo) | the repo holding the netagent binaries | `string` | `"www.banyanops.com"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Google compute instance types | `string` | `"e2-standard-4"` | no |
| <a name="input_minimum_num_of_instances"></a> [minimum\_num\_of\_instances](#input\_minimum\_num\_of\_instances) | The minimum number of instances that should be running | `number` | `2` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the environment being protected. All resources will be prefixed with this name | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Name of the network the AccessTier will belong to | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | GCloud project name where AccessTier is deployed | `string` | n/a | yes |
| <a name="input_redirect_http_to_https"></a> [redirect\_http\_to\_https](#input\_redirect\_http\_to\_https) | If true, requests to the AccessTier on port 80 will be redirected to port 443 | `bool` | `false` | no |
| <a name="input_refresh_token"></a> [refresh\_token](#input\_refresh\_token) | API token generated from the Banyan console | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region in which to create the Accestier | `string` | n/a | yes |
| <a name="input_site_domain_names"></a> [site\_domain\_names](#input\_site\_domain\_names) | List of aliases or CNAMEs that will direct traffic to this AccessTier | `list(string)` | n/a | yes |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | Name to use when registering this AccessTier with the console | `string` | n/a | yes |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Name of the subnetwork the AccessTier will belong to | `string` | n/a | yes |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | DataDog API key to enable sending connection metrics into DataDog | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_ip_address"></a> [lb\_ip\_address](#output\_lb\_ip\_address) | External IP address of the load balancer |


## To Do

- [ ] Add support for access event rate-limiting paramters
- [ ] Adjust kernel tunables according to Banyan best-practice docs

## Authors

Module created and managed by [Todd Radel](https://github.com/tradel).

## License

Licensed under Apache 2. See [LICENSE](LICENSE) for details.

[banyan-security]: https://banyansecurity.io

Needs cloudNAT setup on the network used so instances can talk outside of their network