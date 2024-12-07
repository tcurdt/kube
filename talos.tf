# Generate Talos configurations
resource "null_resource" "talos_config" {

  provisioner "local-exec" {
    command = <<-EOT
      talosctl gen config \
        talos-cluster \
        https://${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}:6443 \
        --force \
        --output-dir ./talos-config \
        --config-patch-control-plane @patches/controlplane.yaml \
        --config-patch-worker @patches/worker.yaml \
        ${local.is_single_node ? "--config-patch @patches/single.yaml" : ""}
    EOT
  }
}

# Apply controlplane configuration
resource "null_resource" "talos_apply_controlplane" {
  depends_on = [null_resource.talos_config]

  for_each = toset(var.control_plane_nodes)

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[each.key].ipv4_address} 50000; do
        echo "Waiting for Talos API..."
        sleep 10
      done

      talosctl --talosconfig=./talos-config/talosconfig \
        apply-config \
        --nodes ${hcloud_server.machine[each.key].ipv4_address} \
        --file ./talos-config/controlplane.yaml \
        --insecure
    EOT
  }
}

# Apply worker configuration
resource "null_resource" "talos_apply_worker" {
  depends_on = [null_resource.talos_apply_controlplane]

  for_each = toset(var.worker_nodes)

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[each.key].ipv4_address} 50000; do
        echo "Waiting for Talos API..."
        sleep 10
      done

      talosctl --talosconfig=./talos-config/talosconfig \
        apply-config \
        --nodes ${hcloud_server.machine[each.key].ipv4_address} \
        --file ./talos-config/worker.yaml \
        --insecure
    EOT
  }
}

# Bootstrap the cluster
resource "null_resource" "talos_bootstrap" {
  depends_on = [
    null_resource.talos_apply_controlplane,
    null_resource.talos_apply_worker
  ]

  provisioner "local-exec" {
    command = <<-EOT
      until nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 50000; do
        echo "Waiting for Talos API..."
        sleep 10
      done

      talosctl --talosconfig=./talos-config/talosconfig \
        config endpoint ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}
      talosctl --talosconfig=./talos-config/talosconfig \
        config node ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address}

      talosctl --talosconfig=./talos-config/talosconfig \
        bootstrap
    EOT
  }
}

# Get kubeconfig
resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.talos_bootstrap]

  provisioner "local-exec" {
    command = <<-EOT
      while ! nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 50000; do
        echo "Waiting for Talos API..."
        sleep 5
      done
      while ! nc -z ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} 6443; do
        echo "Waiting for Kubernetes API..."
        sleep 5
      done

      talosctl --talosconfig=./talos-config/talosconfig \
        kubeconfig \
        --nodes ${hcloud_server.machine[var.control_plane_nodes[0]].ipv4_address} \
        -f ./kubeconfig
    EOT
  }
}
