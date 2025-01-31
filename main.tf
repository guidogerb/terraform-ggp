provider "aws" {
  region                   = var.default-region
  shared_credentials_files = ["~/.aws/credentials", "~/.aws/config"]
  profile                  = "471112830678_GuidGerbAdmins"
}

locals {
  module_defaults = {
    default-region = var.default-region
    common_tags    = var.common_tags
    default-azs    = var.default-azs
    date-time      = formatdate("YYYYMMDDhhmmss", timestamp())
  }
  my-ip = "74.213.199.191"
}

module "vpc" {
  source       = "./modules/vpc"
  defaults     = local.module_defaults
  prepend-name = "GGP-${var.default-region}-vpc-"
  my-ip        = local.my-ip
}

data "aws_subnet" "public-subnet-1" {
  depends_on = [module.vpc]
  filter {
    name   = "tag:Name"
    values = ["GGP-${var.default-region}-vpc-public-subnet-1"]
  }
}

data "aws_subnet" "private-subnet-1" {
  depends_on = [module.vpc]
  filter {
    name   = "tag:Name"
    values = ["GGP-${var.default-region}-vpc-private-subnet-1"]
  }
}

/*module "provision-ec2-s3-buckets" {
  source       = "./modules/provision-ec2-s3-buckets"
  defaults     = local.module_defaults
  prepend-name = "GGP-${var.default-region}-provision-ec2-s3-buckets-"
  account-id        = var.account-id
}*/

/*** Below are modules that can be deleted to reduce cost **/
/*
module "nat-gateway" {
  source            = "./modules/nat-gateway"
  vpc_id            = module.vpc.vpc_id
  defaults          = local.module_defaults
  prepend-name      = "GGP-${var.default-region}-nat-gateway-"
  public-subnet-id  = data.aws_subnet.public-subnet-1.id
  private-subnet-id = data.aws_subnet.private-subnet-1.id
  my-ip             = local.my-ip
}

module "build-deepseek-ec2" {
  source       = "./modules/build-deepseek-ec2"
  defaults     = local.module_defaults
  prepend-name = "GGP-${var.default-region}-build-deepseek-ec2-"

  ec2_data_bucket_name   = module.provision-ec2-s3-buckets.ec2_data_bucket_name
  ec2_backup_bucket_name = module.provision-ec2-s3-buckets.ec2_backup_bucket_name
  subnet_id              = data.aws_subnet.private-subnet-1.id

  instance-type    = "c6i.32xlarge"  // "x1e.8xlarge" "g6.12xlarge" "g5.24xlarge" "p5.48xlarge" "p4de.24xlarge" "m6id.24xlarge"
  ec2-ami          = var.ec2-ami
  private_key_path = var.private_key_path
  key-pair         = var.key-pair
  start-instance   = true

  ec2-instance-profile-name = module.provision-ec2-s3-buckets.ec2-instance-profile-name
}
*/
/*

module "provision-ec2" {
  source       = "./modules/provision-ec2"
  defaults     = local.module_defaults
  prepend-name = "GGP-${var.default-region}-provision-ec2-"

  ec2_data_bucket_name   = module.provision-ec2-s3-buckets.ec2_data_bucket_name
  ec2_backup_bucket_name = module.provision-ec2-s3-buckets.ec2_backup_bucket_name
  subnet_id              = data.aws_subnet.private-subnet-1.id

  instance-type    = var.instance-type
  ec2-ami          = var.ec2-ami
  private_key_path = var.private_key_path
  key-pair         = var.key-pair
  start-instance   = true
}

module "cognito" {
  source = "./modules/congito"
  vpc_id = module.vpc.vpc_id
  defaults = local.module_defaults
  prepend-name = "GGP-${var.default-region}-cognito-"
}
*/
