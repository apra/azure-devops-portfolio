# Dev network: one VNet, three purpose-built subnets, one NSG per subnet.
# Naming follows ADR 0002. Subnet names are scoped to the VNet, so they omit env/region.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-portfolio-dev-uks-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

# --- Network security groups (rules come in later layers) ---

resource "azurerm_network_security_group" "appint" {
  name                = "nsg-appint-dev-uks-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_network_security_group" "pe" {
  name                = "nsg-pe-dev-uks-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_network_security_group" "agents" {
  name                = "nsg-agents-dev-uks-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

# --- Subnets ---

# App Service outbound traffic leaves through this subnet (VNet integration).
# It must be delegated to Microsoft.Web/serverFarms and used by nothing else.
resource "azurerm_subnet" "appint" {
  name                 = "snet-appint"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/26"]

  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private endpoints get their IP addresses from this subnet.
# "Enabled" makes the NSG actually apply to private endpoint traffic.
resource "azurerm_subnet" "pe" {
  name                              = "snet-pe"
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = ["10.10.2.0/27"]
  private_endpoint_network_policies = "Enabled"
}

# The private build agent VM will live here.
resource "azurerm_subnet" "agents" {
  name                 = "snet-agents"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.3.0/27"]
}

# --- Attach each NSG to its subnet ---

resource "azurerm_subnet_network_security_group_association" "appint" {
  subnet_id                 = azurerm_subnet.appint.id
  network_security_group_id = azurerm_network_security_group.appint.id
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}

resource "azurerm_subnet_network_security_group_association" "agents" {
  subnet_id                 = azurerm_subnet.agents.id
  network_security_group_id = azurerm_network_security_group.agents.id
}