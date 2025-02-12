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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84"
    }
  }
}

// export SOPS_AGE_KEY_FILE=.sops.age
provider "sops" {
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "helm" {
  kubernetes {
    config_path = ".kubeconfig"
  }
}

provider "kubernetes" {
  config_path = ".kubeconfig"
}

provider "aws" {
  # shared_credentials_files = ["/Users/tcurdt/.aws/credentials"]
  # profile                  = "default"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}
