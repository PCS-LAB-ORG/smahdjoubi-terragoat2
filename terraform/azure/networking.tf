resource "azurerm_virtual_network" "example" {
  count               = local.deploy_vnet ? 1 : 0
  name                = "terragoat-vn-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = local.resource_group_name
  # Create our network watcher (if needed) first so Azure doesn't auto-create one
  depends_on = [azurerm_network_watcher.network_watcher]
  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "eb19f165-9c21-4a7a-96e5-5bb557a38228"
  }
}

resource "azurerm_subnet" "example" {
  count                = local.deploy_vnet ? 1 : 0
  name                 = "terragoat-${var.environment}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.example[0].name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "ni_linux" {
  count               = local.deploy.vms ? 1 : 0
  name                = "terragoat-linux-${var.environment}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example[0].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    git_commit           = "de3bb777f967989c2c3332faea16cb614c55ccc9"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2020-06-17 15:48:15"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "2647f099-dff8-4514-8cef-96159380c02a"
  }
}

resource "azurerm_network_interface" "ni_win" {
  count               = local.deploy.vms ? 1 : 0
  name                = "terragoat-win-${var.environment}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example[0].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    git_commit           = "de3bb777f967989c2c3332faea16cb614c55ccc9"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2020-06-17 15:48:15"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "2b5dbf28-04fb-4151-a637-a731bbe7ed1d"
  }
}

resource "azurerm_network_security_group" "bad_sg" {
  count               = local.deploy.networking ? 1 : 0
  location            = local.location
  name                = "terragoat-${var.environment}"
  resource_group_name = local.resource_group_name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "AllowSSH"
    priority                   = 200
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_port_range     = "22-22"
    destination_address_prefix = "*"
  }

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "AllowRDP"
    priority                   = 300
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_port_range     = "3389-3389"
    destination_address_prefix = "*"
  }
  tags = {
    git_commit           = "5c6b5d60a8aa63a5d37e60f15185d13a967f0542"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2021-05-02 10:06:10"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "1a591ba4-d969-4572-9704-87b5c55c0ba3"
  }
}

# Azure allows only ONE network watcher per region per subscription, and usually
# auto-creates "NetworkWatcher_<region>" in "NetworkWatcherRG". Reuse an existing one
# if present (ignoring the one this stack may have created itself); otherwise create it.
data "azurerm_resources" "network_watchers" {
  count = local.deploy.networking ? 1 : 0
  type  = "Microsoft.Network/networkWatchers"
}

locals {
  normalized_location      = lower(replace(local.location, " ", ""))
  own_network_watcher_name = "terragoat-network-watcher-${var.environment}"
  existing_network_watchers = [
    for w in flatten(data.azurerm_resources.network_watchers[*].resources) : w
    if lower(w.location) == local.normalized_location && !(
      lower(w.name) == lower(local.own_network_watcher_name) && lower(w.resource_group_name) == lower(local.resource_group_name)
    )
  ]
  create_network_watcher         = local.deploy.networking && length(local.existing_network_watchers) == 0
  network_watcher_name           = local.create_network_watcher ? local.own_network_watcher_name : local.existing_network_watchers[0].name
  network_watcher_resource_group = local.create_network_watcher ? local.resource_group_name : local.existing_network_watchers[0].resource_group_name

  # The flow log is a child of the network watcher, so it is created in the watcher's
  # resource group. Skip it when that group is outside our permissions (e.g. NetworkWatcherRG).
  create_flow_log = local.deploy.networking && (
    var.deploy_subscription_resources || lower(local.network_watcher_resource_group) == lower(local.resource_group_name)
  )
}

resource "azurerm_network_watcher" "network_watcher" {
  count               = local.create_network_watcher ? 1 : 0
  location            = local.location
  name                = local.own_network_watcher_name
  resource_group_name = local.resource_group_name
  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "3da368fc-723f-43d2-8e82-08dcc91e5094"
  }
}

# Azure no longer allows creating NSG flow logs (retired July 2025), so the flow log
# targets the virtual network instead. It is still disabled, with no retention.
resource "azurerm_network_watcher_flow_log" "flow_log" {
  count                = local.create_flow_log ? 1 : 0
  name                 = "terragoat-flow-log-${var.environment}"
  enabled              = false
  target_resource_id   = azurerm_virtual_network.example[0].id
  network_watcher_name = local.network_watcher_name
  resource_group_name  = local.network_watcher_resource_group
  location             = local.location
  storage_account_id   = azurerm_storage_account.example[0].id
  retention_policy {
    enabled = false
    days    = 10
  }
  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/networking.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "33a7212e-7f1a-49fc-af73-8e525c5546ec"
  }
}