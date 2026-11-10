# Subscription-scoped: only deployed when var.deploy_subscription_resources = true.
# WARNING: this changes the Defender for Cloud plan for Virtual Machines for the WHOLE subscription.
resource "azurerm_security_center_subscription_pricing" "pricing" {
  count         = var.deploy_subscription_resources ? 1 : 0
  tier          = "Free"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_contact" "contact" {
  count               = var.deploy_subscription_resources ? 1 : 0
  name                = "default1"
  alert_notifications = false
  alerts_to_admins    = false
  email               = "some@email.com"
}
