module "cluster_a" {
  source              = "./modules/talos"
  cluster_name        = "a"
  control_plane_count = 1
  worker_count        = 1
  flux_repository     = "https://github.com/tcurdt/kube.git"
}

# module "cluster_b" {
#   source              = "./modules/talos"
#   cluster_name        = "b"
#   control_plane_count = 1
#   worker_count        = 1
#   flux_repository     = "https://github.com/tcurdt/kube.git"
# }

locals {
  clusters = {
    a = module.cluster_a
    # b = module.cluster_b
  }
}

output "clusters" {
  value = {
    for name, cluster in local.clusters : name => {
      nodes = {
        control_planes = cluster.control_planes
        workers        = cluster.workers
      }
    }
  }
}

output "kubeconfigs" {
  value = {
    for name, cluster in local.clusters : name => cluster.kubeconfig
  }
  sensitive = true
}

output "talosconfigs" {
  value = {
    for name, cluster in local.clusters : name => cluster.talosconfig
  }
  sensitive = true
}
