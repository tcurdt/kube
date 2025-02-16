output "control_planes" {
  value = {
    public_ips  = hcloud_server.control_plane[*].ipv4_address
    private_ips = [for server in hcloud_server.control_plane : tolist(server.network)[0].ip]
  }
}

output "workers" {
  value = {
    public_ips  = hcloud_server.worker[*].ipv4_address
    private_ips = [for server in hcloud_server.worker : tolist(server.network)[0].ip]
  }
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
