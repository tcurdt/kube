variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "eu-central-1"
}


# common

variable "prefix" {
  type        = string
  description = "cluster name and prefix for the resources"
  default     = ""
}

variable "email" {
  type = string
}

# kubernetes

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

variable "flux_repository" {
  type = string
  # full url to the git repository
}

locals {
  is_single_node = length(var.control_plane_nodes) == 1 && length(var.worker_nodes) == 0
  all_nodes      = concat(var.control_plane_nodes, var.worker_nodes)
}

# s3

variable "s3_storage_buckets" {
  type        = list(string)
  description = "backup buckets names"
}

variable "s3_storage_keep_days" {
  type    = number
  default = 1
}


variable "s3_backup_buckets" {
  type        = list(string)
  description = "backup buckets names"
}

variable "s3_backup_keep_days" {
  type    = number
  default = 1
}

# polly