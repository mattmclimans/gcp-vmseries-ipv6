
# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

output "EXTLB_IPv4" {
  value = "${google_compute_address.extlb_ipv4.address}/32"
}

output "EXTLB_IPv6" {
  value = "${google_compute_address.extlb_ipv6.address}/32"
}

output "VMSERIES_CLI" {
  value = "ssh admin@${google_compute_instance.vmseries.network_interface.1.access_config.0.nat_ip} -i ${trim(local.public_key_path, ".pub")}"
}

output "VMSERIES_GUI" {
  value = "https://${google_compute_instance.vmseries.network_interface.1.access_config.0.nat_ip}"
}

output "SSH_INTERNAL_VM" {
  value = (var.create_test_vms == true ? "gcloud compute ssh paloalto@${google_compute_instance.internal_vm.0.name} --zone=${data.google_compute_zones.main.names[0]}" : "")
}
output "SSH_EXTERNAL_VM" {
  value = (var.create_test_vms == true ? "gcloud compute ssh paloalto@${google_compute_instance.external_vm.0.name} --zone=${data.google_compute_zones.main.names[0]}" : "")
}

# output "vmseries_untrust_ipv6" {
#   value = google_compute_instance.vmseries.network_interface.0.ipv6_access_config.0.external_ipv6
# }

# data "google_compute_network" "trust" {
#   name = "${local.prefix}trust-vpc"
# }







# data google_compute_instance "vmseries" {
#   name = "vmseries"
#   zone = local.zone
# }
# output "test2" {
#   value = data.google_compute_instance.vmseries
#  # sensitive = true
# }

# output "test3" {
#   value = google_compute_instance.vmseries.network_interface.0.addresses[0].address_v6
# }
# VM IP : fd20:d42:dc76:0:0:0:0:0

# FW IP : 2600:1900:4000:eba6:0:0:0:0      | 2600:1900:4000:eba6::7c32:0        |  test nptv6 cks-neutral source-ip fd20:d42:dc76:0:0:0:0:0 dest-network 2600:1900:4000:eba6:0:0:0:0/96 
# LB IP : 2600:1900:4000:b1d3:8000:0:0:0   | 2600:1900:4000:b1d3:8000:0:3605:0  |  test nptv6 cks-neutral source-ip fd20:d42:dc76:0:0:0:0:0 dest-network 2600:1900:4000:b1d3:8000:0:0:0/96 

# FW
## curl -6 'http://[2600:1900:4000:eba6:0:0:0:0]:80/'
## curl -6 'http://[2600:1900:4000:eba6::7c32:0]:80/'

# LB
## curl -6 'http://[2600:1900:4000:b1d3:8000:0:0:0]:80/'
## curl -6 'http://[2600:1900:4000:b1d3:8000:0:3605:0]:80/'
