resource "azurerm_subnet" "subnet-web" {
  name                 = "${var.prefix}-subnet-web"
  resource_group_name  = azurerm_resource_group.rg-routewell.name
  virtual_network_name = azurerm_virtual_network.vnet-routewell.name
  address_prefixes     = var.subnet_web_address
}

resource "azurerm_subnet" "subnet-app" {
  name                 = "${var.prefix}-subnet-app"
  resource_group_name  = azurerm_resource_group.rg-routewell.name
  virtual_network_name = azurerm_virtual_network.vnet-routewell.name
  address_prefixes     = var.subnet_app_address
}

resource "azurerm_subnet" "subnet-db" {
  name                 = "${var.prefix}-subnet-db"
  resource_group_name  = azurerm_resource_group.rg-routewell.name
  virtual_network_name = azurerm_virtual_network.vnet-routewell.name
  address_prefixes     = var.subnet_db_address
}