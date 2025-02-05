terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }
}

# provider "talos" {
# }

# provider "helm" {
#   kubernetes {
#     config_path = ".kubeconfig"
#   }
# }

# provider "kubernetes" {
#   config_path = ".kubeconfig"
# }
