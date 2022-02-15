// todo validate the refresh token works otherwise there can be silent failures...

//backend service
resource "google_compute_region_health_check" "backend_service_loadbalancer_health_check" {
  name                = "${var.name}-at-backend-svc-lb-hc"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10
  region              = var.region

  http_health_check {
    port         = 9998
    request_path = "/"
  }
}

locals {
  // install script is assumed to call `$ apt-get install -y banyan-netagent${install_version}`
  // so we prepend the = to at_version if it is specified
  install_version = (var.at_version == "" ? "" : "=${var.at_version}")
  healthcheck_prober_ip_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

resource "google_compute_region_backend_service" "backend_service_accesstier" {
  name                  = "${var.name}-at-backend-svc"
  health_checks         = [google_compute_region_health_check.backend_service_loadbalancer_health_check.id]
  load_balancing_scheme = "EXTERNAL"
  protocol              = "TCP"
  region                = var.region
  backend {
    group = google_compute_region_instance_group_manager.accesstier_rigm.instance_group
  }
}

resource "google_compute_forwarding_rule" "backend_service_forwarding_rule" {
  name                  = "${var.name}-at-backend-svc-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ports                 = [80, 443, 8443]
  backend_service       = google_compute_region_backend_service.backend_service_accesstier.id
  ip_address            = google_compute_address.backend_service_ip_address.address
}


resource "google_compute_region_autoscaler" "accesstier_autoscaler" {
  name   = "${var.name}-at-rigm-autoscaler"
  target = google_compute_region_instance_group_manager.accesstier_rigm.id

  region = var.region
  autoscaling_policy {
    max_replicas = 10
    min_replicas = var.minimum_num_of_instances
    cpu_utilization {
      target = 0.8 // same value as aws autoscaling accesstier
    }
  }
}

// igm
resource "google_compute_region_instance_group_manager" "accesstier_rigm" {
  name = "${var.name}-at-rigm"

  base_instance_name = "${var.name}-accesstier"
  region             = var.region
  version {
    instance_template = google_compute_instance_template.accesstier_template.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.accesstier_health_check.id
    initial_delay_sec = 180 //needs to be tuned
  }

  update_policy {
    minimal_action               = "REPLACE"
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
  }
}

//needs to be tuned
resource "google_compute_health_check" "accesstier_health_check" {
  name                = "${var.name}-at-autohealing-hc"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds


  http_health_check {
    request_path = "/"
    port         = "9998"
  }
}

// instance details
resource "google_compute_instance_template" "accesstier_template" {
  name_prefix = "${var.name}-at-template-"
  description = "This template is used for access tiers"

  tags         = setunion(google_compute_firewall.accesstier_ports.target_tags, google_compute_firewall.accesstier_ssh.target_tags, google_compute_firewall.healthcheck.target_tags)
  region       = var.region
  machine_type = var.machine_type

  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = data.google_compute_image.accesstier_image.self_link
    disk_size_gb = 10
    disk_type    = "pd-ssd"
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.accesstier_subnet.name
    access_config { // needs to be removed once we want to make these be private.
      // should give this a publi ip
    }
  }

  metadata = {
    shutdown-script = file("${path.module}/scripts/shutdown.sh")
  }

  // todo add these tuning values to either image or startup script https://docs.banyanops.com/docs/banyan-components/netagent/deploy/tuning/
  metadata_startup_script = join("", concat([
    "#!/bin/bash -ex\n",
    "apt-get update -y\n",
    "apt-get install -y jq tar gzip curl sed\n",
    "netplan set ethernets.ens4.addresses=[${google_compute_address.backend_service_ip_address.address}/32] && netplan apply\n", // needed for direct server response, lb doesn't change ip address to the vm's so netagent ignores it
    "curl https://${var.deb_repo}/onramp/deb-repo/banyan.key | apt-key add -\n",
    "apt-add-repository 'deb https://${var.deb_repo}/onramp/deb-repo xenial main'\n",
    "apt-get install -y banyan-netagent${local.install_version}\n",
    "cd /opt/banyan-packages\n",
    //    "while [ -f /var/run/yum.pid ]; do sleep 1; done\n", would be good to find something similar for apt-get
    "BANYAN_ACCESS_TIER=true ",
    "BANYAN_REDIRECT_TO_HTTPS=${var.redirect_http_to_https} ",
    "BANYAN_SITE_NAME=${var.site_name} ",
    "BANYAN_SITE_ADDRESS=${google_compute_address.backend_service_ip_address.address} ",
    "BANYAN_SITE_DOMAIN_NAMES=", join(",", var.site_domain_names), " ",
    "BANYAN_SITE_AUTOSCALE=true ",
    "BANYAN_API=${var.api_server} ",
    "BANYAN_HOST_TAGS= ",
    "./install ${var.refresh_token} ${var.cluster_name} \n",
  ]))

}

resource "google_compute_firewall" "accesstier_ssh" {
  name          = "${var.name}-accesstier-ssh"
  network       = data.google_compute_network.accesstier_network.name
  target_tags   = ["${var.name}-accesstier-ssh"]
  source_ranges = var.ssh_source_ip_ranges
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "accesstier_ports" {
  name          = "${var.name}-accesstier-ports"
  network       = data.google_compute_network.accesstier_network.name
  target_tags   = ["${var.name}-accesstier-ports"]
  source_ranges = var.service_source_ip_ranges
  source_tags   = var.service_source_tags
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8443", "9998"]
  }
}

// Allow access to the healthcheck
resource "google_compute_firewall" "healthcheck" {
  name          = "${var.name}-accesstier-healthcheck"
  network       = data.google_compute_network.accesstier_network.name
  target_tags   = ["${var.name}-accesstier-healthcheck"]
  source_ranges = local.healthcheck_prober_ip_ranges
  allow {
    protocol = "tcp"
    ports    = ["9998"]
  }
}

data "google_compute_image" "accesstier_image" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

// networking
data "google_compute_network" "accesstier_network" {
  name = var.network
}

data "google_compute_subnetwork" "accesstier_subnet" {
  name   = var.subnetwork
  region = var.region
}

resource "google_compute_address" "backend_service_ip_address" {
  name         = "${var.name}-ip-address-at-backend-svc"
  region       = var.region
  address_type = "EXTERNAL"
}

output "lb_ip_address" {
  value = google_compute_address.backend_service_ip_address.address
}
