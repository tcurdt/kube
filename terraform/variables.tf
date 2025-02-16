variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}



# variable "talos_image" {
#   description = "ID or name of the Talos image in Hetzner Cloud"
#   type        = string
# }

# variable "ssh_key_id" {
#   description = "ID of the SSH key to use for the nodes"
#   type        = string
# }

# flux

# variable "flux_repository" {
#   type = string
#   # full url to the git repository
# }

# variable "flux_branch" {
#   type    = string
#   default = "main"
# }

# variable "flux_path" {
#   type    = string
#   default = "./flux/clusters/blue"
# }

# s3

# variable "s3_storage_buckets" {
#   type        = list(string)
#   description = "backup buckets names"
# }

# variable "s3_storage_keep_days" {
#   type    = number
#   default = 1
# }


# variable "s3_backup_buckets" {
#   type        = list(string)
#   description = "backup buckets names"
# }

# variable "s3_backup_keep_days" {
#   type    = number
#   default = 1
# }


# polly
