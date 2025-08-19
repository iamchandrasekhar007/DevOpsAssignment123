output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "firewall_public_ip" {
  value = azurerm_public_ip.fw_pip.ip_address
}

