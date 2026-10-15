variable "aws_region" {
  description = "Local provider region namespace. It does not select or access a real AWS region."
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR used only in the emulator. It must not overlap with a real planned network merely because the examples look similar."
  type        = string
  default     = "10.250.0.0/16"
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
