resource "azurerm_network_security_group" "nsg-web" {
  name                = "${var.prefix}-nsg-web"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  security_rule {
    name                       = "DenyAny"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_subnet.subnet-web]
}

resource "azurerm_subnet_network_security_group_association" "nsg-web-association" {
  subnet_id                 = azurerm_subnet.subnet-web.id
  network_security_group_id = azurerm_network_security_group.nsg-web.id
}


resource "azurerm_network_security_group" "nsg-app" {
  name                = "${var.prefix}-nsg-app"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  security_rule {
    name                       = "Allow8080"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = var.subnet_web_address[0]
    destination_address_prefix = "*"
    destination_port_range     = "8080"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = var.subnet_web_address[0]
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  security_rule {
    name                       = "DenyAny"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  tags = {
    environment = "Production"
  }

  depends_on = [azurerm_subnet.subnet-app]

}

resource "azurerm_subnet_network_security_group_association" "nsg-app-association" {
  subnet_id                 = azurerm_subnet.subnet-app.id
  network_security_group_id = azurerm_network_security_group.nsg-app.id
}



resource "azurerm_network_security_group" "nsg-db" {
  name                = "${var.prefix}-nsg-db"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  security_rule {
    name                       = "AllowPSQL"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = var.subnet_app_address[0]
    destination_address_prefix = "*"
    destination_port_range     = "5432"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = var.subnet_web_address[0]
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  security_rule {
    name                       = "DenyAny"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_subnet.subnet-db]

}

resource "azurerm_subnet_network_security_group_association" "nsg-db-association" {
  subnet_id                 = azurerm_subnet.subnet-db.id
  network_security_group_id = azurerm_network_security_group.nsg-db.id
}


resource "azurerm_network_security_group" "nsg-app-gw" {
  name                = "${var.prefix}-nsg-app-gw"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  security_rule {
    name                       = "AllowHTTPTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    destination_port_range     = "80"
  }


  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
    destination_port_range     = "65200-65535"
  }

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_subnet.subnet-app-gateway]

}

resource "azurerm_subnet_network_security_group_association" "nsg-app-gw-association" {
  subnet_id                 = azurerm_subnet.subnet-app-gateway.id
  network_security_group_id = azurerm_network_security_group.nsg-app-gw.id

  depends_on = [azurerm_subnet.subnet-app-gateway]

}