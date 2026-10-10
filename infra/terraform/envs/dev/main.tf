locals {
  tags = {
    project     = "portfolio"
    environment = "dev"
    owner       = "apra"
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-portfolio-dev-uks-001"
  location = "uksouth"
  tags     = local.tags
}