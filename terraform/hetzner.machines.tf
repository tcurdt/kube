# ssh keys (not needed for talos)

resource "hcloud_ssh_key" "talos" {
  name       = "talos-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHVx2CqRJpgJ7FVIG2A141QlzesUqNgG6eqa+hyA1cf tcurdt@vafer.org"
}

# image

data "hcloud_image" "talos" {
  with_selector = "talos=v1.9.3"
}

# network

resource "hcloud_network" "nodes" {
  name     = "nodes"
  ip_range = "10.0.0.0/16"
  lifecycle {
    create_before_destroy = true
  }
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.nodes.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# machines

resource "hcloud_server" "machine" {
  depends_on = [
    hcloud_network_subnet.nodes
  ]

  for_each = toset(local.all_nodes)
  name     = var.prefix != "" ? "${var.prefix}-${each.key}" : each.key

  server_type = var.server_type
  location    = var.location
  image       = data.hcloud_image.talos.id

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

# resource "hcloud_floating_ip" "control_plane" {
#   for_each = toset(var.control_plane_nodes)
#   name      = var.prefix != "" ? "${var.prefix}-${each.key}-floating" : "${each.key}-floating"
#   type      = "ipv4"
#   server_id = hcloud_server.machine[each.key].id
#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

output "nodes" {
  value = {
    for key in local.all_nodes : key => {
      name       = hcloud_server.machine[key].name
      public_ip4 = hcloud_server.machine[key].ipv4_address
      public_ip6 = hcloud_server.machine[key].ipv6_address
      private_ip = [for n in hcloud_server.machine[key].network : n.ip][0]
      # floating_ip = contains(var.control_plane_nodes, key) ? hcloud_floating_ip.control_plane[key].ip_address : null
    }
  }
}
