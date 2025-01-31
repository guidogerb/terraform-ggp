# terraform-ggp/modules/build-deepseek-ec2/variables.tf

variable "defaults" {
  description = "Default global variables"
  type = object({
    default-region = string
    common_tags    = map(string)
    default-azs    = list(string)
    date-time   = string
  })
}

locals {
  default-region = var.defaults.default-region
  common_tags    = var.defaults.common_tags
  default-azs    = var.defaults.default-azs
  date-time = var.defaults.date-time
  local_tags = {
    Module = "build-deepseek-ec2"
  }
  tags = merge(local.common_tags, local.local_tags)
  azs = [for az in local.default-azs : format("%s%s", local.default-region, az)]
}

variable "prepend-name" {
  description = "String to prepend to resource names and tags in module"
  type = string
  default = "build-deepseek-ec2-"
}

variable "ec2-instance-profile-name" {
  description = "The EC2 instance profile that connects to S3"
  type = string
}

variable "ec2_data_bucket_name" {
  description = "S3 bucket for ec2 data files"
  type = string
}

variable "ec2_backup_bucket_name" {
  description = "S3 bucket used for ec2 snapshots and backups"
  type = string
}

variable "ec2-ami" {
  description = "The Amazon Machine Image (AMI) ID of the instance type you want to launch."
  type = string
  default = "ami-0d55852c857e221a8"
}

variable "private_key_path" {
  description = "Local path to private key"
  type = string
}

variable "instance-type" {
  description = "The EC2 instance type i.e p5.48xlarge"
  type = string
  default = "inf2.48xlarge"
}

variable "subnet_id" {
  description = "The private subnet to launch the instance in"
  type = string
}

variable "key-pair" {
  description = ""
  type = string
}

variable "start-instance" {
  description = "If true, the ec2 instance will start and run"
  type = bool
  default = false
}

variable "deepseek-sg-id" {
  description = "Deepseek Security Group"
  type = string
}

variable "gpu-role-name" {
  description = "Deepseek GPU IAM Role Name"
  type = string
}

variable "most-recent-deep-learning-image-regex" {
  description = "A list of regular expression values to get latest Deep Learning AIM"
  type = list(string)
  default = ["Deep Learning AMI Neuron*Ubuntu 22*"]
}

