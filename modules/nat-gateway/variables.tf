# terraform-ggp/modules/nat-gateway/variables.tf
variable "vpc_id" {
  description = "VPC Id"
  type  = string
}

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
    Module = "nat-gateway"
  }
  tags = merge(local.common_tags, local.local_tags)
  azs = [for az in local.default-azs : format("%s%s", local.default-region, az)]
}

variable "prepend-name" {
  description = "String to prepend to resource names and tags in module"
  type = string
  default = "nat-gateway-"
}

variable "public-subnet-id" {
  description = "Public subnet id to associate nat gateway"
  type = string
}

variable "private-subnet-id" {
  description = "Private subnet id"
  type = string
}

variable "my-ip" {
  description = "My local machine ip"
  type = string
}

variable "ingress-ssh-port" {
  description = "Ingress port for SSH"
  type = number
  default = 22
}

variable "ingress-inference-start-port" {
  description = "Ingress start port for inference"
  type = number
  default = 11434
}

variable "ingress-inference-end-port" {
  description = "Ingress end port for inference"
  type = number
  default = 11439
}