variable "primary_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zones" {
  type    = set(string)
  default = ["us-east-2a", "us-east-2b"]
}

variable "account_id" {
  type    = string
  default = "000000000000"
}
