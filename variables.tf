# terraform-ggp/variables.tf
variable "default-region" {
  description = "Default region"
  type        = string
  default     = "us-east-2"
}

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

variable "account-id" {
  description = "AWS Account id"
  type        = string
  default     = "471112830678"
}

variable "default-azs" {
  description = "The Availability Zones to use"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "private_key_path" {
  description = "Local private key"
  type        = string
  default     = "~/.ssh/ggp-ec2-key"
}

variable "key-pair" {
  description = "Key pair name"
  type        = string
  default     = "ggp-ec2-key"
}

variable "instance-type" {
  description = "The AWS Instance type i.e. p5.48xlarge"
  default     = "inf2.48xlarge"
  type        = string
}

variable "inf2-instance-types" {
  description = "Inf2 (Inferentia2) instances"
  type        = map(string)
  default = {
    8  = "inf2.8xlarge"
    24 = "inf2.24xlarge"
    48 = "inf2.48xlarge"
  }
}

variable "ec2-ami" {
  description = "The AWS image AMI to provision i.e. aws ec2 describe-images --owners amazon --filters \"Name=name,Values=*Neuron*Ubuntu 22*\" --region us-east-2 --query 'Images | sort_by(@, &CreationDate)[-1].[ImageId, Name, CreationDate]' --output table"
  default     = "ami-0d55852c857e221a8"
  type        = string
}

variable "ingress-ssh-port" {
  description = "Ingress port for SSH"
  type        = number
  default     = 11433
}

variable "ingress-inference-start-port" {
  description = "Ingress start port for inference"
  type        = number
  default     = 11434
}

variable "ingress-inference-end-port" {
  description = "Ingress end port for inference"
  type        = number
  default     = 11439
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