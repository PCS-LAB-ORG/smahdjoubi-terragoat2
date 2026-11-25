# terraform/azure/pr_test_vuln.tf

resource "random_integer" "pr_test_suffix" {
  min = 10000
  max = 99999
}

# Triggers High/Critical policies:
# - Public network access enabled (CKV_AZURE_59)
# - Public blob access allowed (CKV_AZURE_190)
# - HTTPS traffic not enforced (CKV_AZURE_3)
# - Storage logging disabled (CKV_AZURE_33)
resource "azurerm_storage_account" "cortex_pr_block_test" {
  name                            = "stcortexprtest${random_integer.pr_test_suffix.result}"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = false
  allow_nested_items_to_be_public = true
  public_network_access_enabled   = true
}

# Triggers High severity policy:
# - SSH (port 22) exposed to the entire internet 0.0.0.0/0 (CKV_AZURE_10)
resource "azurerm_network_security_group" "cortex_pr_block_nsg" {
  name                = "nsg-cortex-pr-block-test"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowAllSSHFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
