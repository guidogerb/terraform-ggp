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
    Module = "deepseek-roles"
  }
  tags = merge(local.common_tags, local.local_tags)
  azs = [for az in local.default-azs : format("%s%s", local.default-region, az)]
}

variable "prepend-name" {
  description = "String to prepend to resource names and tags in module"
  type = string
  default = "deepseek-roles-"
}

variable "my-ip" {
  description = "Your localhost remote public IP"
  type = string
}
