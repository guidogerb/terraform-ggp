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

# 🎯 IAM Role for S3 Access and EC2 Operations
resource "aws_iam_role" "ec2-s3-role" {
  name = "${var.prepend-name}role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.tags, {
    Name = "${var.prepend-name}role"
  })

}

resource "aws_kms_key" "my-kms-key" {
  description             = "My KMS encryption key"
  enable_key_rotation     = true  # Enables automatic key rotation
  is_enabled              = true  # Ensures the key is active
  deletion_window_in_days = 30    # Retention period before deletion

  tags = merge(local.tags, {
    Name = "${var.prepend-name}my-kms-key"
  })

}

# Define KMS Alias for easy reference
resource "aws_kms_alias" "my-kms-key-alias" {
  name          = "alias/kms-key"
  target_key_id = aws_kms_key.my-kms-key.key_id
}


# 🎯 IAM Policy for S3, EC2 Snapshot and Backup
resource "aws_iam_policy" "ec2-s3-policy" {
  name        = "${var.prepend-name}policy"
  description = "Allows EC2 to back up to S3 and create snapshots"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject", "s3:GetBucketLocation"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.ec2-data-bucket.bucket}", "arn:aws:s3:::${aws_s3_bucket.ec2-data-bucket.bucket}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateSnapshot", "ec2:DescribeSnapshots", "ec2:DeleteSnapshot"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateImage", "ec2:DescribeImages", "ec2:DeregisterImage"]
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:StartSession",
          "ssm:DescribeInstanceInformation",
          "ssm:GetConnectionStatus"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": aws_kms_key.my-kms-key.arn
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.prepend-name}policy"
  })

}

resource "aws_iam_role_policy_attachment" "attach_backup_policy" {
  role       = aws_iam_role.ec2-s3-role.name
  policy_arn = aws_iam_policy.ec2-s3-policy.arn
}

# 🎯 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "${var.prepend-name}ec2-instance-profile"
  role = aws_iam_role.ec2-s3-role.name

  tags = merge(local.tags, {
    Name = "${var.prepend-name}ec2-instance-profile"
  })

}

resource "aws_s3_bucket_policy" "s3-bucket-policy-ec2-mount-s3" {
  bucket = aws_s3_bucket.ec2-data-bucket.bucket
  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "${var.prepend-name}s3-bucket-policy-ec2-mount-s3",
    "Statement": [{
      "Sid": "AllowEC2MountpointAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account-id}:role/${aws_iam_role.ec2-s3-role.name}"
      },
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.ec2-data-bucket.bucket}"
    },
      {
        "Sid": "AllowEC2MountpointObjectOperations",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.account-id}:role/${aws_iam_role.ec2-s3-role.name}"
        },
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.ec2-data-bucket.bucket}/*"
      }
    ]
  })
}


