resource "aws_iam_user" "s3_backup_user" {
  name          = "s3-expires-user"
  force_destroy = true
}

resource "aws_iam_access_key" "s3_backup_key" {
  user = aws_iam_user.s3_backup_user.name
}

resource "aws_s3_bucket" "s3_backup_bucket" {
  for_each      = toset(var.s3_backup_buckets)
  bucket        = each.key
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "private_bucket_acl" {
#   for_each = toset(var.buckets)

#   # depends_on = [aws_s3_bucket_ownership_controls.ownership]
#   bucket = aws_s3_bucket.private_bucket[each.key].id

#   acl = "private"
# }

resource "aws_s3_bucket_lifecycle_configuration" "s3_backup_bucket_lifecycle" {
  for_each = toset(var.s3_backup_buckets)

  bucket = aws_s3_bucket.s3_backup_bucket[each.key].id

  rule {
    id     = "expire"
    status = "Enabled"

    #     transition {
    #       days          = 30
    #       storage_class = "STANDARD_IA"
    #       storage_class = "GLACIER"
    #     }

    expiration {
      days = var.s3_backup_keep_days
    }

    # noncurrent_version_expiration {
    #   noncurrent_days = 7
    # }
  }
}

resource "aws_s3_bucket_versioning" "s3_backup_bucket_versioning" {
  for_each = toset(var.s3_backup_buckets)

  bucket = aws_s3_bucket.s3_backup_bucket[each.key].id

  versioning_configuration {
    status = "Enabled"
    # mfa_delete = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_backup_bucket_public_access_block" {
  for_each = toset(var.s3_backup_buckets)

  bucket = aws_s3_bucket.s3_backup_bucket[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "s3_backup_bucket_ownership" {
  for_each = toset(var.s3_backup_buckets)

  bucket = aws_s3_bucket.s3_backup_bucket[each.key].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_iam_user_policy_attachment" "s3_backup_bucket_policy_attachment" {
  for_each = toset(var.s3_backup_buckets)

  user       = aws_iam_user.s3_backup_user.name
  policy_arn = aws_iam_policy.s3_backup_bucket_policy[each.key].arn
}

resource "aws_iam_policy" "s3_backup_bucket_policy" {
  for_each = toset(var.s3_backup_buckets)

  name        = "bucket_policy"
  description = "policy for accessing the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      Resource = [
        aws_s3_bucket.s3_backup_bucket[each.key].arn,
        "${aws_s3_bucket.s3_backup_bucket[each.key].arn}/*"
      ]
    }]
  })
}
