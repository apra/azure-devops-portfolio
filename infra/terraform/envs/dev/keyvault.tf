data "azurerm_client_config" "current" {}

locals {
  # Key Vault names are globally unique; a short suffix derived from the subscription avoids collisions.
  key_vault_suffix = substr(sha256(data.azurerm_client_config.current.subscription_id), 0, 6)
}

resource "azurerm_key_vault" "main" {
  name                = "kv-pf-dev-uks-${local.key_vault_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Authorisation through Azure RBAC role assignments, not vault access policies.
  rbac_authorization_enabled = true

  # Soft delete is always on. Retention cannot be changed after creation, so the minimum
  # is used for this lab; production would use 90 days.
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # No network path in until the private endpoint exists.
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.tags
}