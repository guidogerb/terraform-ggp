# 🎯 S3 Bucket for Storing Snapshots
resource "aws_s3_bucket" "ec2-data-bucket" {
  bucket = lower("${var.prepend-name}ec2-data-bucket")

  tags = merge(local.tags, {
    Name = lower("${var.prepend-name}ec2-data-bucket")
  })

}

# 🎯 S3 Bucket for Storing Snapshots
resource "aws_s3_bucket" "ec2-backup-bucket" {
  bucket = lower("${var.prepend-name}ec2-backup-bucket")

  tags = merge(local.tags, {
    Name = lower("${var.prepend-name}ec2-backup-bucket")
  })

}



