variable "aws_region" {
  description = "Approved AWS Region for this network root. region-a is only a directory placeholder."
  type        = string
  nullable    = false
}

variable "aws_account_id" {
  description = "Vended Network account ID allowed by this root's provider."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "environment" {
  description = "Fixed root environment label for shared network infrastructure."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "shared"
    error_message = "The network hub root environment must be shared."
  }
}

variable "network" {
  description = "Typed regional TGW hub input; ASN and RAM principals must come from approved network governance."
  type = object({
    name               = string
    amazon_side_asn    = number
    ram_principal_arns = set(string)
  })
  nullable = false
}

variable "tags" {
  description = "Required allocation and ownership tags for all network resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
