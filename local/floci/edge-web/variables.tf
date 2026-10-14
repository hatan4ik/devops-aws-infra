variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "zone_id" {
  type    = string
  default = "Z0000000000000"
}

variable "zone_name" {
  type    = string
  default = "example.test"
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
