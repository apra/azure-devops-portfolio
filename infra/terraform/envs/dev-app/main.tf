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