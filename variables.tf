variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "public_key_path" {
  description = "Local path to public SSH key. To generate the key pair use `ssh-keygen -t rsa -C admin -N '' -f id_rsa`  If you do not have a public key, run `ssh-keygen -f ~/.ssh/demo-key -t rsa -C admin`"
  type        = string
}

variable "mgmt_allow_ips" {
  description = "A list of IP addresses to be added to the management network's ingress firewall rule. The IP addresses will be able to access to the VM-Series management interface."
  type        = list(string)
}

variable "create_test_vms" {
  description = "If set to true, test workloads will be deployed to test IPv6 and IPv4 traffic."
  type        = bool
}

variable "vmseries_image" {
  description = "Name of the VM-Series image within the paloaltonetworksgcp-public project.  To list available images, run: `gcloud compute images list --project paloaltonetworksgcp-public --no-standard-images`. If you are using a custom image in a different project, please update `local.vmseries_iamge_url` in `main.tf`."
  type        = string
}



variable "region" {
  description = "GCP Region"
  default     = "us-central1"
  type        = string
}

variable "prefix" {
  description = "Prefix to GCP resource names, an arbitrary string"
  default     = ""
  type        = string
}

variable "subnet_cidr_mgmt" {
  description = "IPv4 CIDR for the VM-Series mgmt subnetwork."
  default     = "10.0.0.0/28"
  type        = string
}

variable "subnet_cidr_untrust" {
  description = "IPv4 CIDR for the VM-Series untrust subnetwork."
  default     = "10.0.1.0/28"
  type        = string
}

variable "subnet_cidr_untrust_lb" {
  description = "IPv4 CIDR for the external load balancer subnetwork."
  default     = "10.0.1.16/28"
  type        = string
}

variable "subnet_cidr_trust" {
  description = "IPv4 CIDR for the VM-Series trust subnetwork."
  default     = "10.0.2.0/28"
  type        = string
}

variable "subnet_cidr_web" {
  description = "IPv4 CIDR for the external network for ingress testing."
  default     = "10.0.3.0/28"
  type        = string
}


variable "subnet_cidr_external" {
  description = "IPv4 CIDR for the external network for ingress testing."
  default     = "192.168.0.0/28"
  type        = string
}


