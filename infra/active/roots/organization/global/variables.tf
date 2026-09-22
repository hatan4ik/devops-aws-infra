variable "aws_region" {
  description = "Approved Region that owns the direct Organizations GitOps state backend and API calls."
  type        = string
  nullable    = false

  validation {
    condition     = var.aws_region == "us-east-2"
    error_message = "The direct Organizations control plane is approved only in us-east-2."
  }
}

variable "management_account_id" {
  description = "AWS Organizations management account permitted by this root provider."
  type        = string
  nullable    = false

  validation {
    condition     = var.management_account_id == "915507704945"
    error_message = "This root is pinned to the approved Organizations management account."
  }
}

variable "organization_id" {
  description = "Observed AWS Organizations ID; the root refuses to operate on any other organization."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must be a valid AWS Organizations identifier."
  }
}

variable "organizational_units" {
  description = "Flat top-level OUs for the direct vending model. Existing accounts are not moved until separately imported and reviewed."
  type        = set(string)
  nullable    = false

  validation {
    condition     = length(var.organizational_units) >= 6 && alltrue([for name in var.organizational_units : can(regex("^[A-Za-z][A-Za-z0-9-]{2,63}$", name))])
    error_message = "organizational_units must contain at least six valid OU names."
  }
}

variable "allowed_regions" {
  description = "Regions permitted by the baseline SCP for future accounts. us-east-1 remains included for global AWS control-plane services."
  type        = set(string)
  nullable    = false

  validation {
    condition     = contains(var.allowed_regions, "us-east-1") && contains(var.allowed_regions, "us-east-2") && contains(var.allowed_regions, "us-west-2")
    error_message = "allowed_regions must include us-east-1, us-east-2, and us-west-2."
  }
}

variable "accounts" {
  description = "Approved new accounts to vend. An empty map creates no accounts; each email must be explicitly supplied rather than inferred."
  type = map(object({
    email         = string
    name          = string
    parent_ou_key = string
    tags          = map(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for account in values(var.accounts) :
      can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", account.email)) &&
      length(trimspace(account.name)) >= 3
    ])
    error_message = "Each account needs an explicit valid email and a name."
  }
}

variable "tags" {
  description = "Required organization-level ownership and cost-allocation tags."
  type = object({
    Application = string
    CostCenter  = string
    Owner       = string
  })
  nullable = false

  validation {
    condition = alltrue([
      length(trimspace(var.tags.Application)) > 0,
      length(trimspace(var.tags.CostCenter)) > 0,
      length(trimspace(var.tags.Owner)) > 0,
    ])
    error_message = "tags.Application, tags.CostCenter, and tags.Owner must be non-empty."
  }
}
