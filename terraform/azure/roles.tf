data "azurerm_subscription" "current_subscription" {}

# Subscription-scoped: only deployed when var.deploy_subscription_resources = true (needs Owner)
resource "azurerm_role_definition" "example" {
  count = var.deploy_subscription_resources ? 1 : 0
  # Role definition names must be unique across the whole Entra ID tenant
  name        = "terragoat-custom-role-${var.environment}${random_integer.rnd_int.result}"
  scope       = data.azurerm_subscription.current_subscription.id
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = ["*"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current_subscription.id
  ]
}