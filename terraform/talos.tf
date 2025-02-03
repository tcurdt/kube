# generate talos configurations
resource "null_resource" "talos_config" {
  for_each = merge(
    { for node in var.control_plane_nodes : node => "controlplane" },
    { for node in var.worker_nodes : node => "worker" }
  )

  provisioner "local-exec" {
    command = <<-EOT
      talosctl gen config \
        talos-cluster \
        https://${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}:6443 \
        --force \
        --output-dir .talosconfig \
        --config-patch-control-plane @config.talos/controlplane.yaml \
        --config-patch-worker @config.talos/worker.yaml \
        ${local.is_single_node ? "--config-patch @config.talos/single.yaml" : ""} \
        --config-patch '{"machine":{"network":{"interfaces":[{"interface":"enp7s0","addresses":["10.0.1.${format("%d", index(local.all_nodes, each.key) + 2)}/24"],"dhcp":false}]}}}'
    EOT
  }
}

# apply controlplane configuration
resource "null_resource" "talos_apply_controlplane" {
  depends_on = [null_resource.talos_config]

  for_each = toset(var.control_plane_nodes)

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[each.key].ipv4_address} 50000; do
        echo "waiting for talos..."
        sleep 10
      done
      echo "talos is ready"

      talosctl --talosconfig=.talosconfig/talosconfig \
        apply-config \
        --nodes ${hcloud_server.machine[each.key].ipv4_address} \
        --file .talosconfig/controlplane.yaml \
        --insecure
    EOT
  }
}

# apply worker configuration
resource "null_resource" "talos_apply_worker" {
  depends_on = [null_resource.talos_apply_controlplane]

  for_each = toset(var.worker_nodes)

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[each.key].ipv4_address} 50000; do
        echo "waiting for talos..."
        sleep 10
      done
      echo "talos is ready"

      talosctl --talosconfig=.talosconfig/talosconfig \
        apply-config \
        --nodes ${hcloud_server.machine[each.key].ipv4_address} \
        --file .talosconfig/worker.yaml \
        --insecure
    EOT
  }
}

# bootstrap the cluster
resource "null_resource" "talos_bootstrap" {
  depends_on = [
    null_resource.talos_apply_controlplane,
    null_resource.talos_apply_worker
  ]

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 50000; do
        echo "waiting for talos..."
        sleep 10
      done
      echo "talos is ready"

      talosctl --talosconfig=.talosconfig/talosconfig \
        config endpoint ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}
      talosctl --talosconfig=.talosconfig/talosconfig \
        config node ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}

      talosctl --talosconfig=.talosconfig/talosconfig \
        bootstrap
    EOT
  }
}

# get kubeconfig
resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.talos_bootstrap]

  provisioner "local-exec" {
    command = <<-EOT

      while ! nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 50000; do
        echo "waiting for talos..."
        sleep 5
      done
      echo "talos is ready"

      while ! nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 6443; do
        echo "waiting for kubernetes..."
        sleep 5
      done
      echo "kubernetes is ready"

      talosctl --talosconfig=.talosconfig/talosconfig \
        kubeconfig \
        --nodes ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} \
        -f .kubeconfig
    EOT
  }
}
