resource "talos_machine_secrets" "this" {
  // talos_version = "v1.9.3"
}

data "talos_machine_configuration" "controlplane" {
  // talos_version = "v1.9.3"
  cluster_name         = var.cluster_name
  cluster_endpoint = "https://${hcloud_server.control_plane[0].ipv4_address}:6443"
  // kubernetes_version = var.kubernetes_version
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = concat([
  ])
  docs = false
  examples = false
}

data "talos_machine_configuration" "worker" {
  // talos_version = "v1.9.3"
  cluster_name         = var.cluster_name
  cluster_endpoint = "https://${hcloud_server.control_plane[0].ipv4_address}:6443"
  // kubernetes_version = var.kubernetes_version
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = concat([

    # yamlencode({
    #   machine = {
    #     network = {
    #       interfaces = [
    #         {
    #           interface = "eth1"
    #           addresses = ["10.0.1.${count.index + 10}/16"]
    #         }
    #       ]
    #     }
    #   }
    # }),
    # yamlencode({
    #   cluster = {
    #     externalCloudProvider = {
    #       enabled = true
    #       manifests = [
    #         # Hetzner Cloud Controller Manager
    #         {
    #           name = "hcloud-ccm"
    #           url  = "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml"
    #         },
    #         # Hetzner CSI Driver
    #         {
    #           name = "hcloud-csi"
    #           url  = "https://raw.githubusercontent.com/hetznercloud/csi-driver/v2.5.1/deploy/kubernetes/hcloud-csi.yml"
    #         }
    #       ]
    #     }
    #   },
    #   machine = {
    #     env = {
    #       HCLOUD_TOKEN = var.hcloud_token
    #     }
    #   }
    # }),
    # yamlencode({
    #   cluster = {
    #     allowSchedulingOnControlPlanes = false
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
  docs = false
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
