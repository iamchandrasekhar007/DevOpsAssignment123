# Route Table for Public Subnets
resource "azurerm_route_table" "public_rt" {
  name                          = var.public_rt_name
  location                      = var.rg_location
  resource_group_name           = azurerm_resource_group.rg.name
  tags                          = var.tags
}

# Default route to Internet for public subnets
resource "azurerm_route" "public_internet" {
  name                   = var.pub_internet_name
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.public_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

# Associate Route Table with Public Subnets
resource "azurerm_subnet_route_table_association" "public_assoc" {
  count          = 3
  subnet_id      = azurerm_subnet.subnet_public[count.index].id
  route_table_id = azurerm_route_table.public_rt.id
}

# Private Subnet Route Table
resource "azurerm_route_table" "private_rt" {
  name                = var.pri_internet_name
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Route traffic to Firewall for Private Subnets
resource "azurerm_route" "private_to_fw" {
  name                   = var.private_egress_name
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.private_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}

# Associate Route Table with Private Subnets
resource "azurerm_subnet_route_table_association" "private_assoc" {
  count          = 3
  subnet_id      = azurerm_subnet.subnet_private[count.index].id
  route_table_id = azurerm_route_table.private_rt.id
}