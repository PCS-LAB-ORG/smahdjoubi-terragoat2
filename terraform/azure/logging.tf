# azurerm_monitor_log_profile was removed in azurerm 4.0 (Azure retired activity log profiles).
# Activity logs are exported with a subscription diagnostic setting instead.
# Misconfiguration: only the "Administrative" category is exported; Security, Policy,
# Alert, etc. are not captured.
# Subscription-scoped: only deployed when var.deploy_subscription_resources = true
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  count              = var.deploy_subscription_resources ? 1 : 0
  name               = "terragoat-activity-log-${var.environment}"
  target_resource_id = data.azurerm_subscription.current_subscription.id
  storage_account_id = azurerm_storage_account.example[0].id

  enabled_log {
    category = "Administrative"
  }
}
