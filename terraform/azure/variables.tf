variable "subscription_id" {
  type        = string
  description = "The subscription ID to deploy into. If null, the ARM_SUBSCRIPTION_ID environment variable is used."
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region. When resource_group_name is set, defaults to that resource group's region."
  default     = null
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Must be all lowercase letters or numbers, max 10 characters (it is used in globally unique resource names)"

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.environment))
    error_message = "environment must be 1-10 lowercase letters or numbers."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of an EXISTING resource group to deploy into. Leave null to let TerraGoat create its own resource group (requires subscription-level Contributor)."
  default     = null
}

variable "deploy_subscription_resources" {
  type        = bool
  description = <<-EOT
    Set to true only if you are Owner of the subscription. Enables the subscription-scoped parts of TerraGoat:
    custom role definition, policy definition + assignment, Defender for Cloud pricing tier + security contact,
    activity log diagnostic setting, automatic resource provider registration and Key Vault purge on destroy.
    Keep false when you only have Contributor on a resource group.
  EOT
  default     = false
}


variable "services" {
  type        = list(string)
  description = <<-EOT
    Services to deploy. Nothing is deployed by default: pick one or more of
    storage, networking, vms, aks, app_gateway, app_service, key_vault, sql, mysql, postgresql
    or "all". Example: ["storage", "networking", "sql"]. See services.tf.
  EOT
  default     = []

  validation {
    condition = alltrue([
      for s in var.services : contains(["all", "storage", "networking", "vms", "aks", "app_gateway", "app_service", "key_vault", "sql", "mysql", "postgresql"], s)
    ])
    error_message = "Unknown service. Valid values: all, storage, networking, vms, aks, app_gateway, app_service, key_vault, sql, mysql, postgresql."
  }
}
