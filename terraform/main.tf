resource "azurerm_resource_group" "rg-routewell" {
  name     = "${var.prefix}-rg"
  location = "westeurope"
}


resource "azurerm_virtual_network" "vnet-routewell" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg-routewell.name
  location            = azurerm_resource_group.rg-routewell.location
  address_space       = var.vnet_address_space
}