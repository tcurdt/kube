resource "talos_machine_secrets" "this" {
  // talos_version = "v1.9.3"
}

data "talos_machine_configuration" "controlplane" {
  # talos_version      = "v1.9.3"
  # kubernetes_version = var.kubernetes_version
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

  ])
  docs     = false
  examples = false
}

data "talos_machine_configuration" "worker" {
  # talos_version      = "v1.9.3"
  # kubernetes_version = var.kubernetes_version
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


resource "talos_machine_bootstrap" "this" {
  depends_on = [
    hcloud_server.control_plane
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.control_plane[0].ipv4_address
  node                 = hcloud_server.control_plane[0].ipv4_address
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.control_plane[0].ipv4_address
}


resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/../../.configs/${var.cluster_name}/kubeconfig"
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/../../.configs/${var.cluster_name}/talosconfig"
}
