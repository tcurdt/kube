variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "location" {
  description = "Hetzner location (nbg1, fsn1, hel1)"
  type        = string
  default     = "fsn1"
}

variable "control_plane_type" {
  description = "Server type for control plane nodes"
  type        = string
  default     = "cpx11"
}

variable "worker_type" {
  description = "Server type for worker nodes"
  type        = string
  default     = "cpx11"
}

variable "image" {
  type    = string
  default = "debian-12"
  # hcloud image list
}

# variable "kubernetes_version" {
#   description = "Kubernetes version to install"
#   type        = string
#   default     = "1.28.3"
# }

variable "control_plane_patches" {
  description = "List of Talos configuration patches for control plane nodes"
  type        = list(string)
  default     = []
}

variable "worker_patches" {
  description = "List of Talos configuration patches for worker nodes"
  type        = list(string)
  default     = []
}

# variable "hcloud_token" {
#   description = "Hetzner Cloud API Token for CSI driver"
#   type        = string
#   sensitive   = true
# }


variable "flux_repository" {
  type    = string
  default = "https://github.com/tcurdt/kube.git"
  # full url to the git repository
}

variable "flux_branch" {
  type    = string
  default = "main"
}

variable "flux_path" {
  type    = string
  default = "./flux/clusters/production"
}
