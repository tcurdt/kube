terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 5.84"
    # }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}


# // export SOPS_AGE_KEY_FILE=.sops.age
# provider "sops" {
# }

#data "sops_file" "secrets" {
#  source_file = "secrets.enc.yaml"
#}


# provider "aws" {
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
#   region     = var.aws_region
# }

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
