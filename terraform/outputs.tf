output "appgw_public_ip" {
  value = azurerm_public_ip.app-public-ip.ip_address
}
output "vm_web_private_ip" {
  value = azurerm_network_interface.nic-web.private_ip_address
}
output "vm_app_private_ip" {
  value = azurerm_network_interface.nic-app.private_ip_address
}
output "vm_db_private_ip" {
  value = azurerm_network_interface.nic-db.private_ip_address
}