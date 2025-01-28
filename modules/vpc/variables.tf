# terraform-ggp/modules/vpc/variables.tf

variable "prepend-name" {
  description = "Prepend name for infrastructure"
  type        = string
}

variable "default-region" {
  description = "Default region"
  type        = string
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
}

variable "azs" {
  type    = list(string)
  default = [format(var.default-region,"%sa"), format(var.default-region, "%sb"), format(var.default-region, "%sc")]
}


