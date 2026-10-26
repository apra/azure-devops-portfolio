# Workload stack: billable resources that are created and destroyed through the
# pipeline. The free foundation (resource group, VNet, subnets, NSGs) lives in
# envs/dev and is only looked up here, never managed.

locals {
  tags = {
    project     = "portfolio"
    environment = "dev"
    owner       = "apra"
    managed-by  = "terraform"
  }
}

data "azurerm_resource_group" "foundation" {
  name = "rg-portfolio-dev-uks-001"
}

data "azurerm_virtual_network" "foundation" {
  name                = "vnet-portfolio-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
}

output "foundation_vnet_address_space" {
  description = "Proves this stack can read the foundation network"
  value       = data.azurerm_virtual_network.foundation.address_space
}

# Who is running Terraform. Used only to derive a stable, unique name suffix.
data "azurerm_client_config" "current" {}

locals {
  # App Service names become public hostnames (<name>.azurewebsites.net), so they
  # must be unique across all of Azure. A short hash of the subscription ID makes
  # the name unique and stays the same after every destroy and re-apply.
  name_suffix = substr(md5(data.azurerm_client_config.current.subscription_id), 0, 6)
}

# The compute. Billed per hour while it exists, whether or not the app is running.
# B1 (Basic) is the lowest tier that supports VNet integration and private endpoints.
resource "azurerm_service_plan" "main" {
  name                = "asp-portfolio-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.tags
}

# The application that runs on the plan.
resource "azurerm_linux_web_app" "main" {
  name                = "app-portfolio-dev-uks-${local.name_suffix}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location
  service_plan_id     = azurerm_service_plan.main.id

  https_only = true

  # Gives the app its own identity in Entra ID, so it can later read Key Vault
  # without any stored password.
  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"

    application_stack {
      python_version = "3.12"
    }
  }

  tags = local.tags
}

output "web_app_default_hostname" {
  description = "Default hostname of the web app. Public for now; closed when the private endpoint is added."
  value       = azurerm_linux_web_app.main.default_hostname
}

# The subnet reserved for build agents. Owned by the foundation stack.
data "azurerm_subnet" "agents" {
  name                 = "snet-agents"
  virtual_network_name = data.azurerm_virtual_network.foundation.name
  resource_group_name  = data.azurerm_resource_group.foundation.name
}

# The VM's network card. No public IP is attached, so nothing on the internet
# can reach this machine.
resource "azurerm_network_interface" "agent" {
  name                = "nic-agent-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.agents.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

# The build agent machine. Agent software is installed in a later PR.
resource "azurerm_linux_virtual_machine" "agent" {
  name                = "vm-agent-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location
  size                = "Standard_D2nls_v6"

  network_interface_ids = [azurerm_network_interface.agent.id]
  # This size only supports the NVMe disk controller (checked with az vm list-skus).
  disk_controller_type = "NVMe"

  # Key-only login. Passwords are disabled, so there is no password to leak.
  # The public key is safe to commit; the private key never leaves my laptop.
  admin_username                  = "azureagent"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureagent"
    public_key = trimspace(file("${path.module}/agent_ssh_key.pub"))
  }

  # Lets the VM get its own Entra identity, so later it can be granted access
  # to Azure resources without any stored password.
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Empty block = boot logs stored in Azure-managed storage.
  boot_diagnostics {}

  tags = local.tags
}

output "agent_private_ip" {
  description = "Private IP of the build agent (no public IP exists)"
  value       = azurerm_network_interface.agent.private_ip_address
}

output "agent_identity_principal_id" {
  description = "Entra object ID of the agent's managed identity, used for RBAC later"
  value       = azurerm_linux_virtual_machine.agent.identity[0].principal_id
}

# Static public IP: the single address all agent outbound traffic will appear to come from.
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# The NAT gateway itself: outbound-only translation for whatever subnet it is attached to.
resource "azurerm_nat_gateway" "main" {
  name                    = "natgw-dev-uks-001"
  resource_group_name     = data.azurerm_resource_group.foundation.name
  location                = data.azurerm_resource_group.foundation.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = local.tags
}

# Attach the public IP to the gateway.
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Attach the gateway to the agents subnet (owned by the foundation stack, referenced by data source).
resource "azurerm_subnet_nat_gateway_association" "agents" {
  subnet_id      = data.azurerm_subnet.agents.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Subnet dedicated to private endpoints, owned by the foundation stack.
data "azurerm_subnet" "pe" {
  name                 = "snet-pe"
  virtual_network_name = data.azurerm_virtual_network.foundation.name
  resource_group_name  = data.azurerm_resource_group.foundation.name
}

# Private DNS zone for App Service private endpoints. Inside linked VNets, the web app's
# hostname resolves to the private endpoint address through this zone.
resource "azurerm_private_dns_zone" "webapp" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.foundation.name
  tags                = local.tags
}

# Link the zone to the foundation VNet so that resources in it can resolve the records.
resource "azurerm_private_dns_zone_virtual_network_link" "webapp" {
  name                  = "link-vnet-portfolio-dev-uks-001"
  resource_group_name   = data.azurerm_resource_group.foundation.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp.name
  virtual_network_id    = data.azurerm_virtual_network.foundation.id
  registration_enabled  = false
  tags                  = local.tags
}

# Private endpoint for the web app. The zone group creates the DNS record automatically.
resource "azurerm_private_endpoint" "webapp" {
  name                = "pe-app-dev-uks-001"
  resource_group_name = data.azurerm_resource_group.foundation.name
  location            = data.azurerm_resource_group.foundation.location
  subnet_id           = data.azurerm_subnet.pe.id

  private_service_connection {
    name                           = "psc-app-dev-uks-001"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.webapp.id]
  }

  tags = local.tags
}