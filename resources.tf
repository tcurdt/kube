resource "hcloud_ssh_key" "talos" {
  name       = "talos-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHVx2CqRJpgJ7FVIG2A141QlzesUqNgG6eqa+hyA1cf tcurdt@vafer.org"
}

data "hcloud_image" "talos" {
  with_selector = "talos=v1.8.3"
}

resource "hcloud_server" "machine" {
  depends_on = [
    hcloud_network_subnet.nodes
  ]

  for_each = toset(local.all_nodes)
  name     = var.prefix != "" ? "${var.prefix}-${each.key}" : each.key

  server_type = var.server_type
  location    = var.location
  image       = data.hcloud_image.talos.id
  // image       = var.image

  ssh_keys = [hcloud_ssh_key.talos.id]
  backups  = false
  # user_data = data.cloudinit_config.server.rendered

  network {
    network_id = hcloud_network.nodes.id
    ip         = "10.0.1.${format("%d", index(local.all_nodes, each.key) + 2)}"
  }

  # lifecycle {
  #   ignore_changes  = [ssh_keys]
  #   prevent_destroy = true
  # }
}
