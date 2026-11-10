resource "azurerm_kubernetes_cluster" "k8s_cluster" {
  count               = local.deploy.aks ? 1 : 0
  dns_prefix          = "terragoat-${var.environment}"
  location            = local.location
  name                = "terragoat-aks-${var.environment}"
  resource_group_name = local.resource_group_name
  identity {
    type = "SystemAssigned"
  }
  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D2_v2"
    node_count = 2
    # AKS sets these defaults server-side; declaring them avoids a perpetual diff
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }
  # No oms_agent block = no Azure Monitor logging for the cluster.
  # (The kube_dashboard add-on was removed from AKS and can no longer be enabled.)
  role_based_access_control_enabled = false

  # AKS creates its own VNet in the node resource group (MC_...). If no network watcher exists
  # in the region yet, Azure then auto-creates NetworkWatcher_<region> in NetworkWatcherRG, which
  # races with (and breaks) our own network watcher creation. Create ours first.
  depends_on = [azurerm_network_watcher.network_watcher]

  tags = {
    git_commit           = "898d5beaec7ffdef6df0d7abecff407362e2a74e"
    git_file             = "terraform/azure/aks.tf"
    git_last_modified_at = "2020-06-17 12:59:55"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "6103d111-864e-42e5-899c-1864de281fd1"
  }
}