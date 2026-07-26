resource "azurerm_network_interface" "nic-web" {
  name                = "${var.prefix}-nic-web"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig1"
    subnet_id                     = azurerm_subnet.subnet-web.id
    private_ip_address_allocation = "Dynamic"

  }
  depends_on = [azurerm_subnet.subnet-web]
}


resource "azurerm_linux_virtual_machine" "vm-web" {
  name                  = "${var.prefix}-vm-web"
  location              = azurerm_resource_group.rg-routewell.location
  resource_group_name   = azurerm_resource_group.rg-routewell.name
  network_interface_ids = [azurerm_network_interface.nic-web.id]
  size                  = "Standard_D2s_v3"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/czar/azure_key/vm-web_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "nic-app" {
  name                = "${var.prefix}-nic-app"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig1"
    subnet_id                     = azurerm_subnet.subnet-app.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.subnet-app]
}


resource "azurerm_linux_virtual_machine" "vm-app" {
  name                  = "${var.prefix}-vm-app"
  location              = azurerm_resource_group.rg-routewell.location
  resource_group_name   = azurerm_resource_group.rg-routewell.name
  network_interface_ids = [azurerm_network_interface.nic-app.id]
  size                  = "Standard_D2s_v3"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/czar/azure_key/vm-web_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "nic-db" {
  name                = "${var.prefix}-nic-db"
  location            = azurerm_resource_group.rg-routewell.location
  resource_group_name = azurerm_resource_group.rg-routewell.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig1"
    subnet_id                     = azurerm_subnet.subnet-db.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.subnet-db]
}


resource "azurerm_linux_virtual_machine" "vm-db" {
  name                  = "${var.prefix}-vm-db"
  location              = azurerm_resource_group.rg-routewell.location
  resource_group_name   = azurerm_resource_group.rg-routewell.name
  network_interface_ids = [azurerm_network_interface.nic-db.id]
  size                  = "Standard_D2s_v3"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/czar/azure_key/vm-web_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}