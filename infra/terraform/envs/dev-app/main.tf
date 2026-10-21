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