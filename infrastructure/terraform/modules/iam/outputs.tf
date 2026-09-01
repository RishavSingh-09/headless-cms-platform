output "s3_policy_arn" { value = aws_iam_policy.s3_media.arn }
output "media_bucket_name" { value = aws_s3_bucket.media.bucket }
