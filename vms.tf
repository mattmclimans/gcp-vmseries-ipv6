# --------------------------------------------------------------------------------------------
# Create external VPC & subnet
# --------------------------------------------------------------------------------------------

resource "google_compute_network" "external" {
  count                    = (local.create_test_vms ? 1 : 0)
  name                     = "${local.prefix}external-vpc"
  routing_mode             = "GLOBAL"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}

resource "google_compute_subnetwork" "external" {
  count            = (local.create_test_vms ? 1 : 0)
  name             = "${local.prefix}external-subnet"
  ip_cidr_range    = local.subnet_cidr_external
  region           = local.region
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
  network          = google_compute_network.external[0].id
}

# --------------------------------------------------------------------------------------------
# Create ingress firewall rules
# --------------------------------------------------------------------------------------------

resource "google_compute_firewall" "external_ipv4" {
  count         = (local.create_test_vms ? 1 : 0)
  name          = "${local.prefix}all-ingress-external"
  network       = google_compute_network.external[0].id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "external_ipv6" {
  count         = (local.create_test_vms ? 1 : 0)
  name          = "${local.prefix}all-ingress-external-ipv6"
  network       = google_compute_network.external[0].id
  source_ranges = ["::/0"]
  direction     = "INGRESS"

  allow {
    protocol = "all"
  }
}

# --------------------------------------------------------------------------------------------
# External VM
# --------------------------------------------------------------------------------------------

resource "google_compute_instance" "external_vm" {
  count                     = (local.create_test_vms ? 1 : 0)
  name                      = "${local.prefix}external-vm"
  project                   = local.project_id
  zone                      = data.google_compute_zones.main.names[0]
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
  }

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/ubuntu-2004-lts-apache"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.external[0].id
    stack_type = "IPV4_IPV6"
    access_config {
      network_tier = "PREMIUM"
    }
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }
}

# --------------------------------------------------------------------------------------------
# Internal VM
# --------------------------------------------------------------------------------------------

resource "google_compute_instance" "internal_vm" {
  count                     = (local.create_test_vms ? 1 : 0)
  name                      = "${local.prefix}internal-vm"
  project                   = local.project_id
  zone                      = data.google_compute_zones.main.names[0]
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
  }

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/panw-gcp-team-testing/global/images/ubuntu-2004-lts-jenkins"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web.id
    network_ip = cidrhost(local.subnet_cidr_web, 10)
    stack_type = "IPV4_IPV6"
  }
}