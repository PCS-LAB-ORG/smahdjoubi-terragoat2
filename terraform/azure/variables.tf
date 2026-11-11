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
  description = "Name of an EXISTING resource group to deploy into. Required unless deploy_subscription_resources = true, in which case leaving it null makes TerraGoat create its own resource group \"terragoat-<environment>\"."
  default     = null

  # Creating a resource group needs subscription-level permissions, so never try it in resource-group mode
  validation {
    condition     = var.resource_group_name != null || var.deploy_subscription_resources
    error_message = "Set resource_group_name (e.g. TF_VAR_resource_group_name) to your existing resource group. TerraGoat only creates its own resource group when deploy_subscription_resources = true, because that needs subscription-level permissions."
  }
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

variable "web_apps_via_azapi" {
  type        = bool
  description = <<-EOT
    Create the two web apps with the azapi provider instead of azurerm_linux_web_app. Set to true if
    the deploy fails with AuthorizationFailed on "Microsoft.Web/checknameavailability": the azurerm
    resource runs that name check at subscription scope, which Contributor on a resource group may not
    allow. The apps and their misconfigurations are identical, but IaC scanners don't analyse azapi.
  EOT
  default     = false
}

# ---------------------------------------------------------------------------
# Compute sizing. Not every VM size is available in every region / zone for every
# subscription (409 "SkuNotAvailable"). The Azure portal's VM create page shows which
# sizes and zones your subscription can use in a region.
# ---------------------------------------------------------------------------
variable "vm_size" {
  type        = string
  description = "Size of the Linux and Windows VMs (service \"vms\"), e.g. Standard_D2s_v3, Standard_D4s_v3, Standard_E2s_v3, Standard_B2s."
  default     = "Standard_D2s_v3"
}

variable "aks_node_size" {
  type        = string
  description = "Size of the 2 AKS nodes (service \"aks\"). Needs at least 2 vCPUs / 4 GiB RAM."
  default     = "Standard_D2s_v3"
}

variable "zone" {
  type        = string
  description = "Availability zone (\"1\", \"2\" or \"3\") for the VMs and AKS nodes. Leave null for no zone; set it when your VM size is only available in some zones of the region."
  default     = null

  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], coalesce(var.zone, "x"))
    error_message = "zone must be \"1\", \"2\", \"3\" or null."
  }
}
