resource "hcloud_ssh_key" "talos" {
  name       = "talos-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHVx2CqRJpgJ7FVIG2A141QlzesUqNgG6eqa+hyA1cf tcurdt@vafer.org"
}

resource "hcloud_network" "talos" {
  name     = "talos-network"
  ip_range = "10.0.0.0/16"
  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "hcloud_network_subnet" "talos" {
  network_id   = hcloud_network.talos.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_firewall" "talos" {
  name = "${var.cluster_name}-firewall"

  # Talos
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = ["0.0.0.0/0"]
    description = "Talos API"
  }

  # Kubernetes
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0"]
    description = "Kubernetes API"
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = ["10.0.0.0/8"]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = ["10.0.0.0/8"]
  }
}

data "hcloud_image" "talos" {
  with_selector = "talos=v1.9.3"
}

resource "hcloud_server" "control_plane" {
  count       = var.control_plane_count
  name        = "${var.cluster_name}-c-${count.index + 1}"
  server_type = var.control_plane_type
  image       = data.hcloud_image.talos.id
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.talos.id]

  network {
    network_id = hcloud_network.talos.id
    ip         = "10.0.1.${count.index + 2}"
  }

  firewall_ids = [hcloud_firewall.talos.id]

  labels = {
    cluster = var.cluster_name
    role    = "control-plane"
  }
}

resource "hcloud_server" "workers" {
  count       = var.worker_count
  name        = "${var.cluster_name}-w-${count.index + 1}"
  server_type = var.worker_type
  image       = data.hcloud_image.talos.id
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.talos.id]

  network {
    network_id = hcloud_network.talos.id
    ip         = "10.0.2.${count.index + 2}"
  }

  firewall_ids = [hcloud_firewall.talos.id]

  labels = {
    cluster = var.cluster_name
    role    = "worker"
  }
}
