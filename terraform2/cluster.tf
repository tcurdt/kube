module "cluster_a" {
  source              = "./modules/talos"
  cluster_name        = "a"
  control_plane_count = 1
  worker_count        = 0
  # location            = "fsn1"
  flux_repository = "https://github.com/tcurdt/kube.git"
}

# module "cluster_b" {
#   source = "./modules/talos"
#   cluster_name        = "b"
#   control_plane_count = 1
#   worker_count        = 1
#   # location            = "fsn1"
#   flux_repository = "https://github.com/tcurdt/kube.git"
# }
