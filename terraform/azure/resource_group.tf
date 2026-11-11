# If var.resource_group_name is set, TerraGoat deploys into that EXISTING resource group
# (only Contributor on that group is needed). Otherwise it creates "terragoat-<environment>".
data "azurerm_resource_group" "existing" {
  count = var.resource_group_name == null ? 0 : 1
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "example" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "terragoat-${var.environment}"
  location = local.location
  tags = {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/azure/resource_group.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "80b3b0ca-e0d8-4266-8a1f-12c71afd7e18"
  }
}

locals {
  resource_group_name = var.resource_group_name == null ? azurerm_resource_group.example[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_id   = var.resource_group_name == null ? azurerm_resource_group.example[0].id : data.azurerm_resource_group.existing[0].id
  # Explicit var.location wins, then the existing resource group's region, then East US
  location = coalesce(
    var.location,
    one(data.azurerm_resource_group.existing[*].location),
    "East US",
  )
}
