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
  tags     = merge(local.tags, { deployed-via = "github-actions" })
}