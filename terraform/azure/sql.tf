# Azure SQL: one server carries all the SQL misconfigurations (older TerraGoat versions
# deployed 7 near-identical extra servers in mssql.tf; they added no unique findings).
# azurerm_sql_server / azurerm_sql_firewall_rule were removed in azurerm 4.0
resource "azurerm_mssql_firewall_rule" "example" {
  count            = local.deploy.sql ? 1 : 0
  name             = "terragoat-firewall-rule-${var.environment}"
  server_id        = azurerm_mssql_server.example[0].id
  start_ip_address = "10.0.17.62"
  end_ip_address   = "10.0.17.62"
}

resource "azurerm_mssql_server" "example" {
  count                        = local.deploy.sql ? 1 : 0
  name                         = "terragoat-sqlserver-${var.environment}${random_integer.rnd_int.result}"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "ariel"
  administrator_login_password = "Aa12345678"
  tags = merge({
    environment = var.environment
    terragoat   = "true"
    }, {
    git_commit           = "81738b80d571fa3034633690d13ffb460e1e7dea"
    git_file             = "terraform/azure/sql.tf"
    git_last_modified_at = "2020-06-19 21:14:50"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "e5ec3432-e61f-4244-b59e-9ecc24ddd4cb"
  })
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  count                      = local.deploy.sql ? 1 : 0
  resource_group_name        = local.resource_group_name
  server_name                = azurerm_mssql_server.example[0].name
  state                      = "Enabled"
  storage_endpoint           = azurerm_storage_account.example[0].primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.example[0].primary_access_key
  disabled_alerts = [
    "Sql_Injection",
    "Data_Exfiltration"
  ]
  retention_days = 20
}

# Azure Database for MySQL Single Server was retired; azurerm_mysql_server was removed in 4.0.
resource "azurerm_mysql_flexible_server" "example" {
  count               = local.deploy.mysql ? 1 : 0
  name                = "terragoat-mysql-${var.environment}${random_integer.rnd_int.result}"
  location            = local.location
  resource_group_name = local.resource_group_name

  administrator_login    = "terragoat${var.environment}"
  administrator_password = random_string.password.result

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  storage {
    size_gb           = 20
    auto_grow_enabled = true
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  # No delegated_subnet_id = public network access
  tags = {
    git_commit           = "81738b80d571fa3034633690d13ffb460e1e7dea"
    git_file             = "terraform/azure/sql.tf"
    git_last_modified_at = "2020-06-19 21:14:50"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "1ac18c16-09a4-41c9-9a66-6f514050178e"
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

# Equivalent of the old ssl_enforcement_enabled = false
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  count               = local.deploy.mysql ? 1 : 0
  name                = "require_secure_transport"
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mysql_flexible_server.example[0].name
  value               = "OFF"
}

# Azure Database for PostgreSQL Single Server was retired; azurerm_postgresql_server was removed in 4.0.
resource "azurerm_postgresql_flexible_server" "example" {
  count                         = local.deploy.postgresql ? 1 : 0
  name                          = "terragoat-postgresql-${var.environment}${random_integer.rnd_int.result}"
  location                      = local.location
  resource_group_name           = local.resource_group_name
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  auto_grow_enabled             = true
  administrator_login           = "terragoat"
  administrator_password        = "Aa12345678"
  version                       = "16"
  public_network_access_enabled = true
  tags = {
    git_commit           = "81738b80d571fa3034633690d13ffb460e1e7dea"
    git_file             = "terraform/azure/sql.tf"
    git_last_modified_at = "2020-06-19 21:14:50"
    git_last_modified_by = "Adin.Ermie@outlook.com"
    git_modifiers        = "Adin.Ermie/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "9eae126d-9404-4511-9c32-2243457df459"
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

# Equivalent of the old ssl_enforcement_enabled = false
resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  count     = local.deploy.postgresql ? 1 : 0
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.example[0].id
  value     = "off"
}

resource "azurerm_postgresql_flexible_server_configuration" "thrtottling_config" {
  count     = local.deploy.postgresql ? 1 : 0
  name      = "connection_throttle.enable"
  server_id = azurerm_postgresql_flexible_server.example[0].id
  value     = "off"

  # Flexible server rejects concurrent configuration updates
  depends_on = [azurerm_postgresql_flexible_server_configuration.require_secure_transport]
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  count     = local.deploy.postgresql ? 1 : 0
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.example[0].id
  value     = "off"

  depends_on = [azurerm_postgresql_flexible_server_configuration.thrtottling_config]
}
