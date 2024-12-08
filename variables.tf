variable "prefix" {
  type        = string
  description = "cluster name used as prefix for the machine names"
  default     = ""
}

variable "control_plane_nodes" {
  type        = list(string)
  description = "names of control plane nodes"
  default     = []
}

variable "worker_nodes" {
  type        = list(string)
  description = "names of worker-only nodes"
  default     = []
}

variable "image" {
  type    = string
  default = "debian-12"
  # hcloud image list
}

variable "server_type" {
  type    = string
  default = "cpx11"
  # hcloud server-type list
}

variable "location" {
  type    = string
  default = "fsn1"
  # hcloud location list
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "email" {
  type = string
}

variable "flux_repository" {
  type = string
  # full url to the git repository
}

locals {
  is_single_node = length(var.control_plane_nodes) == 1 && length(var.worker_nodes) == 0
  all_nodes      = concat(var.control_plane_nodes, var.worker_nodes)
}
