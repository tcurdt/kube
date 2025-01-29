resource "local_file" "config_file" {
  filename = "/path/to/config.yml"
  content  = <<-EOT
    database:
      password: ${data.sops_file.secrets.data["live.db_password"]}
    api:
      key: ${data.sops_file.secrets.data["live.api_key"]}
  EOT

  file_permission = "0600"
}

resource "local_file" "api_config" {
  filename = "/path/to/api.conf"
  content  = data.sops_file.secrets.data["live.api_key"]

  file_permission = "0600"
}
