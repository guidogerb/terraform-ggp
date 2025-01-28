# terraform-ggp/modules/vpc/variables.tf

variable "prepend-name" {
  description = "Prepend name for infrastructure"
  type        = string
}

variable "default-region" {
  description = "Default region"
  type        = string
}

variable "default-azs" {
  description = "The Availability Zones"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags from parent module"
  type        = map(string)
}

locals {
  local_tags = {
    Module = "vpc"
  }
  tags = merge(var.common_tags, local.local_tags)
  azs = [for az in var.default-azs : format("%s%s", var.default-region, az)]
}


