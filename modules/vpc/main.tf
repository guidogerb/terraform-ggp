locals {
  cidr_blocks = {
    vpc = "10.0.0.0/16"
    public_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/20"]
    private_subnets = ["10.0.80.0/20", "10.0.96.0/19", "10.0.128.0/19"]
    database_subnets = ["10.0.160.0/20", "10.0.176.0/20", "10.0.192.0/19"]
  }
}

resource "aws_vpc" "main" {
  cidr_block  = local.cidr_blocks.vpc
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.prepend-name}main-vpc"
  })
}

resource "aws_subnet" "public-subnet" {
  count             = length(local.cidr_blocks.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.public_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private-subnet" {
  count             = length(local.cidr_blocks.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.private_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}private-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "database-subnet" {
  count             = length(local.cidr_blocks.database_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.database_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}databases-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}internet-gateway"
  })
}

resource "aws_route_table" "route-table-public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}route-table-public"
  })
}

resource "aws_default_security_group" "default-security-group" {
  vpc_id = aws_vpc.main.id

  # Additional rule to allow SSH from specific IP
  ingress {
    from_port   = var.ingress-ssh-port
    to_port     = var.ingress-ssh-port
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.prepend-name}default-sg"
  })
}

resource "aws_security_group" "allow_ssh_private_subnets" {
  count = length(local.cidr_blocks.private_subnets)

  vpc_id = aws_vpc.main.id

  # Additional rule to allow SSH from specific IP
  ingress {
    from_port   = var.ingress-ssh-port
    to_port     = var.ingress-ssh-port
    protocol    = "tcp"
    cidr_blocks = ["${var.my-ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.prepend-name}allow-ssh-private-subnets-${count.index}-sg"
  })
}

resource "aws_s3_bucket" "s3-bucket-vpc-logs" {
  bucket = lower("${var.prepend-name}s3-bucket-logs")

  tags = merge(local.tags, {
    Name = "${var.prepend-name}s3-bucket-logs"
  })
}

resource "aws_s3_bucket_policy" "s3_bucket_policy_vpc_logs" {
  bucket = aws_s3_bucket.s3-bucket-vpc-logs.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "MyLogBucketPolicy",
    "Statement": [
      {
        "Sid": "AllowPutObject",
        "Effect": "Allow",
        "Principal": {"Service": "logs.${local.default-region}.amazonaws.com"},
        "Action": ["s3:PutObject", "s3:GetObject"],
        "Resource": "${aws_s3_bucket.s3-bucket-vpc-logs.arn}/*"
      },
      {
        "Sid": "AllowGetBucketAcl",
        "Effect": "Allow",
        "Principal": {"Service": "logs.${local.default-region}.amazonaws.com"},
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.s3-bucket-vpc-logs.arn}"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name = "${var.prepend-name}flow-logs-group"
  retention_in_days = 60 // Retain logs for 60 days

  tags = merge(local.tags, {
    Name = "${var.prepend-name}flow-logs-group"
  })
}

resource "aws_iam_role" "flow-log-role" {
  name = "${var.prepend-name}flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(local.tags, {
    Name = "${var.prepend-name}flow-log-role"
  })
}

resource "aws_iam_role_policy" "flow-log-policy" {
  name = "${var.prepend-name}flow-log-policy"
  role = aws_iam_role.flow-log-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams"
        ],
        "Effect": "Allow",
        "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_flow_log" "flow_log" {
  iam_role_arn        = aws_iam_role.flow-log-role.arn
  log_destination     = aws_cloudwatch_log_group.cloudwatch-log-group.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type        = "ALL"
  vpc_id              = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${var.prepend-name}flow-log"
  })
}
