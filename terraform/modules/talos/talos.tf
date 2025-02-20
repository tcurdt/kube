data "hcloud_image" "talos" {
  with_selector = "talos=v1.9.3,type=cpx21"
}

resource "talos_machine_secrets" "this" {
}

data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${hcloud_server.control_plane[0].ipv4_address}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = concat([

    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }),

    yamlencode({
      machine = {
        kubelet = {
          extraMounts = [
            {
              destination = "/var/local-path-provisioner"
              type        = "bind"
              source      = "/var/local-path-provisioner"
              options     = ["bind", "rshared", "rw"]
            }
          ]
        }
      }
    }),

    # var.worker_count == 0 ? yamlencode({
    #   machine = {
    #     nodeLabels = {
    #       "node-role.kubernetes.io/control-plane" = ""
    #     }
    #     kubelet = {
    #       extraArgs = {
    #         "node-labels" = "node-role.kubernetes.io/control-plane="
    #       }
    #     }
    #   }
    # }) : null,

  ])
  docs     = false
  examples = false
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${hcloud_server.control_plane[0].ipv4_address}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = concat([

    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }),

    yamlencode({
      machine = {
        kubelet = {
          extraMounts = [
            {
              destination = "/var/local-path-provisioner"
              type        = "bind"
              source      = "/var/local-path-provisioner"
              options     = ["bind", "rshared", "rw"]
            }
          ]
        }
      }
    }),

    # yamlencode({
    #   machine = {
    #     env = {
    #       HCLOUD_TOKEN = var.hcloud_token
    #     }
    #   }
    #   cluster = {
    #     externalCloudProvider = {
    #       enabled = true
    #       manifests = [
    #         {
    #           name = "hcloud-ccm"
    #           url  = "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml"
    #         },
    #         {
    #           name = "hcloud-csi"
    #           url  = "https://raw.githubusercontent.com/hetznercloud/csi-driver/v2.5.1/deploy/kubernetes/hcloud-csi.yml"
    #         }
    #       ]
    #     }
    #     storage = {
    #       config = {
    #         storageClasses = [{
    #           name : "hcloud-volumes"
    #           default : true
    #           deletionPolicy : "Delete"
    #           allowVolumeExpansion : true
    #           provisioner : "csi.hetzner.cloud"
    #           volumeBindingMode : "WaitForFirstConsumer"
    #           parameters = {
    #             "type" : "cx11"
    #           }
    #         }]
    #       }
    #     }
    #   }
    # })

  ])
  docs     = false
  examples = false
}


data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = hcloud_server.control_plane[*].ipv4_address
}

resource "talos_machine_configuration_apply" "control_plane" {
  count                       = length(hcloud_server.control_plane)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  endpoint                    = hcloud_server.control_plane[0].ipv4_address
  node                        = hcloud_server.control_plane[count.index].ipv4_address
}

resource "talos_machine_configuration_apply" "worker" {
  count                       = length(hcloud_server.worker)
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  // endpoint                    = hcloud_server.control_plane[0].ipv4_address
  endpoint = hcloud_server.worker[count.index].ipv4_address
  node     = hcloud_server.worker[count.index].ipv4_address
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [hcloud_server.control_plane]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.control_plane[0].ipv4_address
  node                 = hcloud_server.control_plane[0].ipv4_address
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.control_plane[0].ipv4_address
}

# write out the access keys

resource "local_file" "talosconfig" {
  depends_on = [talos_machine_bootstrap.this]
  content    = data.talos_client_configuration.this.talos_config
  filename   = "${path.module}/../../.configs/${var.cluster_name}/talosconfig"
}

resource "local_file" "kubeconfig" {
  depends_on = [talos_cluster_kubeconfig.this]
  content    = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename   = "${path.module}/../../.configs/${var.cluster_name}/kubeconfig"
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [local_file.kubeconfig]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "${path.module}/../../.configs/${var.cluster_name}/kubeconfig"
    }
    command = <<-EOT
      timeout=300
      counter=0
      echo $KUBECONFIG
      until kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=30s; do
        counter=$((counter + 30))
        if [ $counter -gt $timeout ]; then
          echo "kube not ready - timeout"
          exit 1
        fi
        echo "waiting for kube..."
        sleep 30
      done
    EOT
  }
}

resource "kubernetes_config_map" "cluster_ready" {
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name      = "cluster-ready"
    namespace = "kube-system"
  }

  data = {
    "ready" = "true"
  }
}
