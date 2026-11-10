# Service selection. Nothing is deployed unless it is listed in var.services, e.g.
#   export TF_VAR_services='["storage","networking","sql"]'     (or '["all"]')
# Subscription-scoped resources are controlled separately by var.deploy_subscription_resources.
locals {
  all_services = ["storage", "networking", "vms", "aks", "app_gateway", "app_service", "key_vault", "sql", "mysql", "postgresql"]
  selected     = contains(var.services, "all") ? local.all_services : var.services
  deploy       = { for s in local.all_services : s => contains(local.selected, s) }

  # Shared pieces, created automatically when a selected service needs them:
  # - the VNet + default subnet: VMs (NICs) and the App Gateway (its own subnet) need it
  deploy_vnet = local.deploy.networking || local.deploy.vms || local.deploy.app_gateway
  # - the "tgsa" storage account: target of the flow log, SQL threat detection and activity log export
  deploy_log_storage = local.deploy.storage || local.deploy.networking || local.deploy.sql || var.deploy_subscription_resources
}

check "services_selected" {
  assert {
    condition     = length(var.services) > 0 || var.deploy_subscription_resources
    error_message = "No services selected, so nothing will be deployed. Set e.g. TF_VAR_services='[\"storage\",\"networking\"]' or TF_VAR_services='[\"all\"]'."
  }
}
