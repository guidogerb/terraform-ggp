# terraform-ggp/variables.tf

variable "common_tags" {
  description = "Common tags to be attached to all resources"
  type        = map(string)
  default = {
    Owner       = "471112830678"
    CreatedBy   = "Gary Gerber"
    Project     = "GuidoGerb Publishing"
    Environment = "production"
    GeneratedBy = "Terraform"
  }
}

variable "default-region" {
  description = "Default region"
  type        = string
  default     = "us-east-2"
}

variable "prepend-name" {
  description = "Prepend name for infrastructure"
  type        = string
  default     = "GGP-us-east-2-"
}

variable "default-azs" {
  description = "The Availability Zones"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "plans" {
  type = map(any)
  default = {
    "5USD"  = "1xCPU-1GB"
    "10USD" = "1xCPU-2GB"
    "20USD" = "2xCPU-4GB"
  }
}

variable "storage_sizes" {
  type = map(any)
  default = {
    "1xCPU-1GB" = "25"
    "1xCPU-2GB" = "50"
    "2xCPU-4GB" = "80"
  }
}
variable "templates" {
  type = map(any)
  default = {
    "ubuntu18" = "01000000-0000-4000-8000-000030080200"
    "centos7"  = "01000000-0000-4000-8000-000050010300"
    "debian9"  = "01000000-0000-4000-8000-000020040100"
  }
}

variable "set_password" {
  type    = bool
  default = false
}

variable "users" {
  type    = list(any)
  default = ["root", "user1", "user2"]
}

variable "plan" {
  type    = string
  default = "10USD"
}

variable "template" {
  type    = string
  default = "ubuntu18"
}