variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.251.0.0/16"
}
variable "naming_base_tags" {
  description = "Local-only allocation tags merged with canonical tags from aws.modules.naming."
  type        = map(string)
  default = {
    DeploymentScope = "local"
    Emulator        = "floci"
    Purpose         = "integration"
  }
}
