output "ec2_data_bucket_name" {
  value = aws_s3_bucket.ec2-data-bucket.bucket
  description = "The name of the S3 bucket used for EC2 data."
}

output "ec2_backup_bucket_name" {
  value = aws_s3_bucket.ec2-backup-bucket.bucket
  description = "The name of the S3 bucket used for EC2 backups."
}