resource "azurerm_key_vault" "example" {
  count               = local.deploy.key_vault ? 1 : 0
  name                = "tg-kv-${var.environment}${random_integer.rnd_int.result}"
  location            = local.location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  # Minimum allowed; a destroyed vault stays soft-deleted this long if it can't be purged
  soft_delete_retention_days = 7
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    # Permission names are case-sensitive in azurerm 4.x. Terraform also needs
    # Get/Delete/Purge to read back and destroy the key and secret below.
    key_permissions = [
      "Create",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover",
      "GetRotationPolicy",
    ]
    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover",
    ]
  }
  tags = merge({
    environment = var.environment
    terragoat   = true
    }, {
    git_commit           = "81738b80d571fa3034633690d13ffb460e1e7dea"
    git_file             = "terraform/azure/key_vault.tf"
    git_last_modified_at = "2020-06-19 21:14:50"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "79afeacc-248a-4015-a4fa-76a6a57f06e2"
  })
}

resource "azurerm_key_vault_key" "generated" {
  count        = local.deploy.key_vault ? 1 : 0
  name         = "terragoat-generated-certificate-${var.environment}"
  key_vault_id = azurerm_key_vault.example[0].id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/key_vault.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "afbc6e13-63d9-4e6c-8914-d58b7744b5dd"
  }
}

resource "azurerm_key_vault_secret" "secret" {
  count        = local.deploy.key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.example[0].id
  name         = "terragoat-secret-${var.environment}"
  value        = random_string.password.result
  tags = {
    git_commit           = "f8ff847bb69370bbe03b3d2b70db586ff6c867fc"
    git_file             = "terraform/azure/key_vault.tf"
    git_last_modified_at = "2020-06-19 21:16:08"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "40517524-f05d-485b-bfbe-3fa0dbee511e"
  }
}