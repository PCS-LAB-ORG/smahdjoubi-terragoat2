locals {
  backend_address_pool_name      = "terragoat-beap"
  frontend_port_name             = "terragoat-feport"
  frontend_ip_configuration_name = "terragoat-feip"
  http_setting_name              = "terragoat-be-htst"
  listener_name                  = "terragoat-httplstn"
  request_routing_rule_name      = "terragoat-rqrt"
}

resource "azurerm_subnet" "appgw" {
  count                = local.deploy.app_gateway ? 1 : 0
  name                 = "terragoat-appgw-${var.environment}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.example[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "appgw" {
  count               = local.deploy.app_gateway ? 1 : 0
  name                = "terragoat-appgw-pip-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "network" {
  count               = local.deploy.app_gateway ? 1 : 0
  name                = "terragoat-appgw-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.location

  # Standard_v2 rather than WAF_v2 (the v1 Standard_Small SKU is retired)
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "terragoat-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw[0].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }
  ####Missing WAF block: As per azure best practices, it is important to have a web application firewall enabled at application gateway.


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw[0].id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
  tags = {
    git_commit           = "b07a42ebd74b8f0ba647e20b872474b1c29b4814"
    git_file             = "terraform/azure/application_gateway.tf"
    git_last_modified_at = "2021-05-02 10:08:55"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "harkiratbhardwaj/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "3f62753b-3d20-4fa7-b402-b780234a14d8"
  }
}
