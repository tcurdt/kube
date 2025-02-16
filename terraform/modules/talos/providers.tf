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
      version = "~> 0.7"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["clusters"][0]["cluster"]["server"]
    cluster_ca_certificate = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["clusters"][0]["cluster"]["certificate-authority-data"])
    client_certificate     = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["users"][0]["user"]["client-certificate-data"])
    client_key            = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["users"][0]["user"]["client-key-data"])
  }
}

provider "kubernetes" {
  host                   = yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["clusters"][0]["cluster"]["certificate-authority-data"])
  client_certificate     = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["users"][0]["user"]["client-certificate-data"])
  client_key            = base64decode(yamldecode(nonsensitive(talos_cluster_kubeconfig.this.kubeconfig_raw))["users"][0]["user"]["client-key-data"])
}
