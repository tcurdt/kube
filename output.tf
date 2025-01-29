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

output "s3_storage_buckets" {
  value = {
    for key in var.s3_storage_buckets :
    "${key}" => aws_s3_bucket.s3_storage_bucket[key].arn
  }
}

output "s3_storage_user" {
  value = aws_iam_user.s3_storage_user.name
}

output "s3_storage_key_id" {
  value = nonsensitive(aws_iam_access_key.s3_storage_key.id)
}

output "s3_storage_key_secret" {
  value = nonsensitive(aws_iam_access_key.s3_storage_key.secret)
}


output "s3_backup_buckets" {
  value = {
    for key in var.s3_backup_buckets :
    "${key}" => aws_s3_bucket.s3_backup_bucket[key].arn
  }
}

output "s3_backup_user" {
  value = aws_iam_user.s3_backup_user.name
}

output "s3_backup_key_id" {
  value = nonsensitive(aws_iam_access_key.s3_backup_key.id)
}

output "s3_backup_key_secret" {
  value = nonsensitive(aws_iam_access_key.s3_backup_key.secret)
}


output "polly_access_id" {
  value = nonsensitive(aws_iam_access_key.polly_key.id)
}

output "polly_access_key" {
  value = nonsensitive(aws_iam_access_key.polly_key.secret)
}
