# 🎯 IAM Role for S3 Access and EC2 Operations
resource "aws_iam_role" "ec2-backup-role" {
  name = "${var.prepend-name}ec2-backup-role"

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
    Name = "${var.prepend-name}ec2-backup-role"
  })

}

# 🎯 IAM Policy for S3, EC2 Snapshot and Backup
resource "aws_iam_policy" "ec2-backup-policy" {
  name        = "${var.prepend-name}ec2-backup-policy"
  description = "Allows EC2 to back up to S3 and create snapshots"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${var.ec2_backup_bucket_name}", "arn:aws:s3:::${var.ec2_backup_bucket_name}/*"]
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
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.prepend-name}ec2-backup-policy"
  })

}

resource "aws_iam_role_policy_attachment" "attach_backup_policy" {
  role       = aws_iam_role.ec2-backup-role.name
  policy_arn = aws_iam_policy.ec2-backup-policy.arn
}

# 🎯 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "${var.prepend-name}ec2-instance-profile"
  role = aws_iam_role.ec2-backup-role.name

  tags = merge(local.tags, {
    Name = "${var.prepend-name}ec2-instance-profile"
  })

}

# 🎯 EC2 Instance with Hibernate Enabled
resource "aws_instance" "aws-instance" {
  ami                    = var.ec2-ami
  instance_type          = var.instance-type
  key_name               = var.key-pair
  subnet_id = var.subnet_id
  monitoring             = false
  hibernation            = true
  disable_api_termination = false
  ebs_optimized          = true
  iam_instance_profile   = aws_iam_instance_profile.ec2-instance-profile.name
  count = var.start-instance? 1:0

  root_block_device {
    volume_size           = 500
    volume_type           = "gp3"
    delete_on_termination = false
  }

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y s3fs

    # Create a directory for mounting
    mkdir -p /mnt/s3

    # Mount the S3 bucket using the IAM role
    s3fs ${var.ec2_data_bucket_name} /mnt/s3 -o iam_role=${aws_iam_role.ec2-backup-role.name} -o allow_other

    # Auto-mount on reboot
    echo "s3fs#${var.ec2_data_bucket_name} /mnt/s3 fuse _netdev,allow_other 0 0" >> /etc/fstab
  EOF

  tags = merge(local.tags, {
    Name = "${var.prepend-name}aws-instance"
  })

}
