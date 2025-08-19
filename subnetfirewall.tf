
# AzureFirewallSubnet
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  address_prefixes     = var.firewall_subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}
# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  name                = "nat-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "natgw" {
  name                = "nat-gateway"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
  tags = var.tags
}
resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT to private subnets
resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = 3
  subnet_id      = azurerm_subnet.subnet_private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}

# Route Table for Public Subnets
resource "azurerm_route_table" "public_rt" {
  name                          = "public-rt"
  location                      = var.rg_location
  resource_group_name           = azurerm_resource_group.rg.name
  tags                          = var.tags
}

# Default route to Internet for public subnets
resource "azurerm_route" "public_internet" {
  name                   = "internet-access"
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
  name                = "private-rt"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Route traffic to Firewall for Private Subnets
resource "azurerm_route" "private_to_fw" {
  name                   = "private-egress"
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

# Public IP for Firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "fw-public-ip"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = var.tags
}

# Firewall Policy 
resource "azurerm_firewall_policy" "fw_policy" {
  name                = "fw-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.rg_location
  tags = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "fw" {
  name                = "azure-fw"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags = var.tags

  ip_configuration {
    name                 = "fw-ipcfg"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
}

resource "azurerm_firewall_policy_rule_collection_group" "fw_rules" {
  name                = "fw-rule-group"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id
  priority            = 100

network_rule_collection {
    name     = "allow-http-https"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-web"
      protocols             = ["TCP"]
      source_addresses      = var.private_subnet_prefixes
      destination_addresses = ["*"]
      destination_ports     = ["80", "443"]
    }
  }
 network_rule_collection {
    name     = "deny-specific-ip"
    priority = 200
    action   = "Deny"

    rule {
      name                  = "deny-bad-ip"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["198.51.100.1"]
      destination_ports     = ["*"]
    }
  }
}