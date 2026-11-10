# azurerm_app_service_plan / azurerm_app_service were removed in azurerm 4.0,
# replaced by azurerm_service_plan / azurerm_linux_web_app.
resource "azurerm_service_plan" "example" {
  count               = local.deploy.app_service ? 1 : 0
  name                = "terragoat-app-service-plan-${var.environment}"
  location            = local.location
  resource_group_name = local.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1"
  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/app_service.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "6611bf45-fd5b-467e-b119-d533cd7539b8"
  }
}

resource "azurerm_linux_web_app" "app-service1" {
  count               = local.deploy.app_service ? 1 : 0
  service_plan_id     = azurerm_service_plan.example[0].id
  location            = azurerm_service_plan.example[0].location
  name                = "terragoat-app-service-${var.environment}${random_integer.rnd_int.result}"
  resource_group_name = local.resource_group_name
  https_only          = false
  site_config {
    minimum_tls_version = "1.1"
  }
  tags = {
    git_commit           = "81738b80d571fa3034633690d13ffb460e1e7dea"
    git_file             = "terraform/azure/app_service.tf"
    git_last_modified_at = "2020-06-19 21:14:50"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "13be096d-c599-46e5-bf54-51c6e9732858"
  }
}

resource "azurerm_linux_web_app" "app-service2" {
  count               = local.deploy.app_service ? 1 : 0
  service_plan_id     = azurerm_service_plan.example[0].id
  location            = azurerm_service_plan.example[0].location
  name                = "terragoat-app-service2-${var.environment}${random_integer.rnd_int.result}"
  resource_group_name = local.resource_group_name
  https_only          = true

  site_config {}

  auth_settings {
    enabled = false
  }
  tags = {
    git_commit           = "5c6b5d60a8aa63a5d37e60f15185d13a967f0542"
    git_file             = "terraform/azure/app_service.tf"
    git_last_modified_at = "2021-05-02 10:06:10"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "ec8295ab-af68-4cff-b0f1-b0cf5eaf1b75"
  }
}
