output "nodes" {
  value = {
    for key in local.all_nodes : key => {
      name       = hcloud_server.machine[key].name
      public_ip4 = hcloud_server.machine[key].ipv4_address
      public_ip6 = hcloud_server.machine[key].ipv6_address
      private_ip = [for n in hcloud_server.machine[key].network : n.ip][0]
    }
  }
}
