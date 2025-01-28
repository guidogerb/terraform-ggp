provider "aws" {
  region                  = var.default-region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "471112830678_GuidGerbAdmins"
}

module "vpc" {
  source = "./modules/vpc"

  prepend-name   = var.prepend-name
  default-region = var.default-region
  common_tags    = var.common_tags
  default-azs    = var.default-azs
}

/*


resource "aws_internet_gateway" "gw" {
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name = "${local.prepend-name}Gateway"
  }
}

resource "aws_eip" "nat_ip" {
  vpc = true

  tags = {
    Name = "${local.prepend-name}EIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat_ip.id}"
  subnet_id     = "${aws_subnet.public_a.id}"
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "${local.prepend-name}NatGateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${module.vpc.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "${local.prepend-name}Routes-Public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${module.vpc.vpc_id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

  tags = {
    Name = "${local.prepend-name}Routes-Private"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = "${module.vpc.vpc_id}"
  cidr_block              = "10.1.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Public1-a"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = "${aws_subnet.public_a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public_b" {
  vpc_id                  = "${module.vpc.vpc_id}"
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Public1-b"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = "${aws_subnet.public_b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public_c" {
  vpc_id                  = "${module.vpc.vpc_id}"
  cidr_block              = "10.1.4.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Public1-c"
  }
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = "${aws_subnet.public_c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "private_a" {
  vpc_id                  = "${module.vpc.vpc_id}"
  availability_zone       = "us-east-2a"
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Private1-a"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = "${aws_subnet.private_a.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_subnet" "private_b" {
  vpc_id                  = "${module.vpc.vpc_id}"
  cidr_block              = "10.1.3.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Private1-b"
  }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = "${aws_subnet.private_b.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_subnet" "private_c" {
  vpc_id                  = "${module.vpc.vpc_id}"
  cidr_block              = "10.1.5.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prepend-name}SubNet-VPC-Private1-c"
  }
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = "${aws_subnet.private_c.id}"
  route_table_id = "${aws_route_table.private.id}"
}

*/

################################################################################
# RDS Aurora Module - PostgreSQL
################################################################################

/*
module "aurora_postgresql" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = "${local.name}postgresql"
  engine            = "aurora-postgresql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.database_subnets
  create_security_group = true
  allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks

  replica_scale_enabled = false
  replica_count         = 0

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.dev_postgresql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.dev_postgresql.id
  # enabled_cloudwatch_logs_exports = # NOT SUPPORTED

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "dev_postgresql" {
  name        = "${local.name}aurora-db-postgres-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name}aurora-db-postgres-parameter-group"
  tags = {
    Name = "${local.name}aurora-db-postgres-parameter-group"
  }
}

resource "aws_rds_cluster_parameter_group" "dev_postgresql" {
  name        = "${local.name}aurora-postgres-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name}-aurora-postgres-cluster-parameter-group"
  tags = {
    Name = "${local.name}aurora-postgres-cluster-parameter-group"
  }
}
*/
