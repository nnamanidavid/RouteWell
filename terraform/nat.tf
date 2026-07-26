resource "azurerm_public_ip" "route_pip" {
  name                = "${var.prefix}-PIP"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "${var.prefix}-NatGateway"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.route_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "app-subnet_nat_gateway_association" {
  subnet_id      = azurerm_subnet.subnet-app.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id

  depends_on = [azurerm_subnet.subnet-app]
}

resource "azurerm_subnet_nat_gateway_association" "db-subnet_nat_gateway_association" {
  subnet_id      = azurerm_subnet.subnet-db.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
  depends_on     = [azurerm_subnet.subnet-db]
}