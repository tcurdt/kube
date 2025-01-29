resource "aws_iam_user" "polly_user" {
  name          = "polly-api-user"
  force_destroy = true
}

resource "aws_iam_access_key" "polly_key" {
  user = aws_iam_user.polly_user.name
}

resource "aws_iam_user_policy" "polly_policy" {
  name = "polly-api-access"
  user = aws_iam_user.polly_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech"
        ]
        Resource = ["*"]
      }
    ]
  })
}
