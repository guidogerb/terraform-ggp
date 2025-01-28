locals {
  cidr_blocks = {
    vpc = "10.0.0.0/16"
    public_subnets = ["10.0.1.0/24", "10.0.1.1/24", "10.0.1.2/24"]
    private_subnets = ["10.0.2.0/24", "10.0.2.1/24", "10.0.2.2/24"]
    database_subnets = ["10.0.3.0/24", "10.0.3.1/24", "10.0.3.2/24"]
  }
}

resource "aws_vpc" "main" {
  cidr_block  = local.cidr_blocks.vpc

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-main-vpc-${var.default-region}"
  })
}

resource "aws_subnet" "public-subnet" {
  count             = length(local.cidr_blocks.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.public_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private-subnet" {
  count             = length(local.cidr_blocks.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.private_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-private-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "database-subnet" {
  count             = length(local.cidr_blocks.database_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_blocks.database_subnets[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-databases-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-internet-gateway"
  })
}

resource "aws_route_table" "route-table-public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-route-table-public"
  })
}

resource "aws_default_security_group" "default-security-group" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-default-security-group"
  })
}

resource "aws_security_group" "allow_ssh_private_subnets" {
  count = length(local.cidr_blocks.private_subnets)

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.cidr_blocks.private_subnets[count.index]]
  }

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-allow-ssh-private-subnets-${count.index}"
  })
}

resource "aws_s3_bucket" "s3-bucket-vpc-logs" {
  bucket = "${var.prepend-name}-vpc-logs"

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-vpc-logs"
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
        "Principal": {"Service": "logs.${var.default-region}.amazonaws.com"},
        "Action": ["s3:PutObject", "s3:GetObject"],
        "Resource": "${aws_s3_bucket.s3-bucket-vpc-logs.arn}/*"
      },
      {
        "Sid": "AllowGetBucketAcl",
        "Effect": "Allow",
        "Principal": {"Service": "logs.${var.default-region}.amazonaws.com"},
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.s3-bucket-vpc-logs.arn}"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name = "${var.prepend-name}-flow-logs-group"
  retention_in_days = 60 // Retain logs for 60 days

  tags = merge(local.tags, {
    Name = "${var.prepend-name}-flow-logs-group"
  })
}

resource "aws_iam_role" "flow-log-role" {
  name = "${var.prepend-name}-flow-log-role"

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
    Name = "${var.prepend-name}-flow-log-role"
  })
}

resource "aws_iam_role_policy" "flow-log-policy" {
  name = "${var.prepend-name}-flow-log-policy"
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
    Name = "${var.prepend-name}-vpc-flow-log"
  })
}
