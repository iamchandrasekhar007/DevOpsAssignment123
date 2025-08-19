resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_ip_address
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
}

# Public Subnets

resource "azurerm_subnet" "subnet_public" {
  count               = 3
  name                = "public-subnet-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.public_subnet_prefixes[count.index]]
}

# Private Subnets
resource "azurerm_subnet" "subnet_private" {
  count               = 3
  name                = "private-subnet-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_subnet_prefixes[count.index]]
}
