resource "azurerm_managed_disk" "example" {
  count                = local.deploy.storage ? 1 : 0
  name                 = "terragoat-disk-${var.environment}"
  location             = local.location
  resource_group_name  = local.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
  # No encryption_settings block = disk is not encrypted with Azure Disk Encryption
  tags = {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/azure/storage.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "d17da7b3-f1c5-4723-9f77-d1b9069459c7"
  }
}

resource "azurerm_storage_account" "example" {
  count                    = local.deploy_log_storage ? 1 : 0
  name                     = "tgsa${var.environment}${random_integer.rnd_int.result}"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags = {
    git_commit           = "5c6b5d60a8aa63a5d37e60f15185d13a967f0542"
    git_file             = "terraform/azure/storage.tf"
    git_last_modified_at = "2021-05-02 10:06:10"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "23861ff4-c42d-495e-80ac-776c74035f43"
  }
}

# Queue logging only records writes, not reads or deletes.
# (queue_properties inside azurerm_storage_account is deprecated in azurerm 4.x)
resource "azurerm_storage_account_queue_properties" "example" {
  count              = local.deploy.storage ? 1 : 0
  storage_account_id = azurerm_storage_account.example[0].id
  logging {
    delete                = false
    read                  = false
    write                 = true
    version               = "1.0"
    retention_policy_days = 10
  }
  hour_metrics {
    include_apis          = true
    version               = "1.0"
    retention_policy_days = 10
  }
  minute_metrics {
    include_apis          = true
    version               = "1.0"
    retention_policy_days = 10
  }
}

# Separate account for the firewall misconfiguration (no "AzureServices" bypass).
# On the account above it would block the flow log, activity log export and SQL auditing.
resource "azurerm_storage_account" "restricted" {
  count                    = local.deploy.storage ? 1 : 0
  name                     = "tgfw${var.environment}${random_integer.rnd_int.result}"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_network_rules" "test" {
  count              = local.deploy.storage ? 1 : 0
  storage_account_id = azurerm_storage_account.restricted[0].id

  default_action = "Deny"
  # Azure rejects private/loopback addresses (the original 127.0.0.1); this is a reserved documentation IP
  ip_rules = ["203.0.113.10"]
  bypass   = ["Metrics"]
}
