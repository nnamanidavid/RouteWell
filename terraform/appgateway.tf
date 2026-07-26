resource "azurerm_subnet" "subnet-app-gateway" {
  name                 = "${var.prefix}-subnet-app-gateway"
  resource_group_name  = azurerm_resource_group.rg-routewell.name
  virtual_network_name = azurerm_virtual_network.vnet-routewell.name
  address_prefixes     = var.subnet_app_gateway_address
}


resource "azurerm_public_ip" "app-public-ip" {
  name                = "${var.prefix}-app-gateway-pip"
  resource_group_name = azurerm_resource_group.rg-routewell.name
  location            = azurerm_resource_group.rg-routewell.location
  allocation_method   = "Static"
}


locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet-routewell.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet-routewell.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet-routewell.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet-routewell.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet-routewell.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet-routewell.name}-rqrt"
}

resource "azurerm_application_gateway" "rg-app-gateway" {
  name                = "${var.prefix}-appgateway"
  resource_group_name = azurerm_resource_group.rg-routewell.name
  location            = azurerm_resource_group.rg-routewell.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.app-gw-waf.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "rg-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet-app-gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app-public-ip.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_network_interface.nic-web.private_ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
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
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}


resource "azurerm_web_application_firewall_policy" "app-gw-waf" {
  name                = "routewell-waf-policy"
  resource_group_name = azurerm_resource_group.rg-routewell.name
  location            = azurerm_resource_group.rg-routewell.location

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}