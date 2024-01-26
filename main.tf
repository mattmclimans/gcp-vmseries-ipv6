# --------------------------------------------------------------------------------------------
# Provider configuration
# --------------------------------------------------------------------------------------------

terraform {}

provider "google" {
  project = local.project_id
  region  = local.region
}

data "google_compute_zones" "main" {}

# --------------------------------------------------------------------------------------------
# Local variables
# --------------------------------------------------------------------------------------------

locals {
  project_id             = var.project_id
  region                 = var.region
  vmseries_image         = var.vmseries_image
  public_key_path        = var.public_key_path
  mgmt_allow_ips         = var.mgmt_allow_ips
  prefix                 = var.prefix
  subnet_cidr_mgmt       = var.subnet_cidr_mgmt
  subnet_cidr_untrust    = var.subnet_cidr_untrust
  subnet_cidr_untrust_lb = var.subnet_cidr_untrust_lb
  subnet_cidr_trust      = var.subnet_cidr_trust
  subnet_cidr_web        = var.subnet_cidr_web
  subnet_cidr_external   = var.subnet_cidr_external
  create_test_vms        = var.create_test_vms
}

# --------------------------------------------------------------------------------------------
# Create VPC networks
# --------------------------------------------------------------------------------------------

resource "google_compute_network" "mgmt" {
  name                     = "${local.prefix}mgmt-vpc"
  routing_mode             = "GLOBAL"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}


resource "google_compute_network" "untrust" {
  name                     = "${local.prefix}untrust-vpc"
  routing_mode             = "GLOBAL"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}


resource "google_compute_network" "trust" {
  name                            = "${local.prefix}trust-vpc"
  routing_mode                    = "GLOBAL"
  auto_create_subnetworks         = false
  enable_ula_internal_ipv6        = true
  delete_default_routes_on_create = true
}

# --------------------------------------------------------------------------------------------
# Create subnets
# --------------------------------------------------------------------------------------------

resource "google_compute_subnetwork" "mgmt" {
  name             = "${local.prefix}mgmt-subnet"
  ip_cidr_range    = local.subnet_cidr_mgmt
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
  network          = google_compute_network.mgmt.id
}


resource "google_compute_subnetwork" "untrust" {
  name             = "${local.prefix}untrust-subnet"
  ip_cidr_range    = local.subnet_cidr_untrust
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
  network          = google_compute_network.untrust.id
}


resource "google_compute_subnetwork" "untrust_lb" {
  name             = "${local.prefix}untrust-lb-subnet"
  ip_cidr_range    = local.subnet_cidr_untrust_lb
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
  network          = google_compute_network.untrust.id
}


resource "google_compute_subnetwork" "trust" {
  name             = "${local.prefix}trust-subnet"
  ip_cidr_range    = local.subnet_cidr_trust
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"
  network          = google_compute_network.trust.id
}

resource "google_compute_subnetwork" "web" {
  name             = "${local.prefix}web-subnet"
  ip_cidr_range    = local.subnet_cidr_web
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"
  network          = google_compute_network.trust.id
}

# --------------------------------------------------------------------------------------------
# Create ingress firewall rules
# --------------------------------------------------------------------------------------------

resource "google_compute_firewall" "mgmt_ipv4" {
  name          = "${local.prefix}all-ingress-mgmt"
  network       = google_compute_network.mgmt.id
  source_ranges = var.mgmt_allow_ips

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }
}


resource "google_compute_firewall" "untrust_ipv4" {
  name          = "${local.prefix}all-ingress-untrust"
  network       = google_compute_network.untrust.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}


resource "google_compute_firewall" "untrust_ipv6" {
  name          = "${local.prefix}all-ingress-untrust-ipv6"
  network       = google_compute_network.untrust.id
  source_ranges = ["::/0"]
  direction     = "INGRESS"

  allow {
    protocol = "all"
  }
}


resource "google_compute_firewall" "trust_ipv4" {
  name          = "${local.prefix}all-ingress-trust"
  network       = google_compute_network.trust.id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}


resource "google_compute_firewall" "trust_ipv6" {
  name          = "${local.prefix}all-ingress-trust-ipv6"
  network       = google_compute_network.trust.id
  source_ranges = ["::/0"]
  direction     = "INGRESS"

  allow {
    protocol = "all"
  }
}


# --------------------------------------------------------------------------------------------
# Create VM-Series
# --------------------------------------------------------------------------------------------

# Service account for bootstrapping
module "iam_service_account" {
  source             = "github.com/PaloAltoNetworks/terraform-google-vmseries-modules//modules/iam_service_account?ref=main"
  service_account_id = "${local.prefix}vmseries-mig-sa"
  project_id         = local.project_id
}


# # Create the bootstrap storage bucket.
# module "bootstrap" {
#   source          = "PaloAltoNetworks/vmseries-modules/google//modules/bootstrap"
#   service_account = module.iam_service_account.email
#   location        = "US"
#   files = {
#     "bootstrap_files/init-cfg.txt"  = "config/init-cfg.txt"
#     "bootstrap_files/bootstrap.xml" = "config/bootstrap.xml"
#     "bootstrap_files/authcodes"     = "license/authcodes"
#   }
# }

# Create VM-Series
resource "google_compute_instance" "vmseries" {
  name                      = "${local.prefix}vmseries"
  zone                      = data.google_compute_zones.main.names[0]
  machine_type              = "n2-standard-4"
  can_ip_forward            = true
  allow_stopping_for_update = true

  metadata = {
    mgmt-interface-swap = "enable"
    # vmseries-bootstrap-gce-storagebucket = module.bootstrap.bucket_name
    serial-port-enable = true
    ssh-keys           = "admin:${file(local.public_key_path)}"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.untrust.id
    stack_type = "IPV4_IPV6"
    access_config {
      network_tier = "PREMIUM"
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    stack_type = "IPV4_IPV6"
    access_config {
      network_tier = "PREMIUM"
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.trust.id
    stack_type = "IPV4_IPV6"
  }

  boot_disk {
    initialize_params {
      image = local.vmseries_image
      type  = "pd-standard"
    }
  }

  service_account {
    email = module.iam_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  depends_on = [
    # module.bootstrap,
    module.iam_service_account
  ]
}


# Create instance group
resource "google_compute_instance_group" "vmseries" {
  name = "${local.prefix}vmseries"
  zone = data.google_compute_zones.main.names[0]

  instances = [
    google_compute_instance.vmseries.id
  ]
}


# --------------------------------------------------------------------------------------------
# Create an external load balancer to distribute traffic to VM-Series trust interfaces.
# --------------------------------------------------------------------------------------------

resource "google_compute_region_health_check" "extlb" {
  name                = "${local.prefix}vmseries-extlb-hc"
  project             = var.project_id
  region              = var.region
  check_interval_sec  = 3
  healthy_threshold   = 1
  timeout_sec         = 1
  unhealthy_threshold = 1

  http_health_check {
    port         = 80
    request_path = "/php/login.php"
  }
}


resource "google_compute_address" "extlb_ipv4" {
  name         = "${local.prefix}vmseries-extlb-pip-ipv4"
  region       = local.region
  network_tier = "PREMIUM"
  address_type = "EXTERNAL"
}


resource "google_compute_address" "extlb_ipv6" {
  name               = "${local.prefix}vmseries-extlb-pip-ipv6"
  region             = local.region
  network_tier       = "PREMIUM"
  address_type       = "EXTERNAL"
  ip_version         = "IPV6"
  ipv6_endpoint_type = "NETLB"
  subnetwork         = google_compute_subnetwork.untrust_lb.id
}


resource "google_compute_forwarding_rule" "extlb_ipv4" {
  name                  = "${local.prefix}vmseries-extlb-rule-ipv4"
  project               = var.project_id
  region                = var.region
  network_tier          = "PREMIUM"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  backend_service       = google_compute_region_backend_service.extlb.self_link
  ip_address            = google_compute_address.extlb_ipv4.address
}


resource "google_compute_forwarding_rule" "extlb_ipv6" {
  name                  = "${local.prefix}vmseries-extlb-rule-ipv6"
  project               = var.project_id
  region                = var.region
  network_tier          = "PREMIUM"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  backend_service       = google_compute_region_backend_service.extlb.self_link
  ip_address            = google_compute_address.extlb_ipv6.id
  ip_version            = "IPV6"
  subnetwork            = google_compute_subnetwork.untrust_lb.id
}


resource "google_compute_region_backend_service" "extlb" {
  provider              = google-beta
  name                  = "${local.prefix}vmseries-extlb"
  project               = var.project_id
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.extlb.self_link]
  protocol              = "UNSPECIFIED"

  connection_tracking_policy {
    tracking_mode                                = "PER_SESSION"
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }

  backend {
    group = google_compute_instance_group.vmseries.self_link
  }
}
