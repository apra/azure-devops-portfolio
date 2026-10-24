# Terraform refreshes every resource in state before it plans. For a Linux web
# app that refresh calls the "list config" action, which the built-in Reader
# role does not include. Without it, every plan of the dev-app stack fails with
# a 403 once the web app exists.
#
# This custom role grants exactly that one action and nothing else.
resource "azurerm_role_definition" "plan_app_service_config_read" {
  name        = "Portfolio Plan - App Service Config Reader"
  scope       = data.azurerm_subscription.current.id
  description = "Lets the read-only plan identity refresh App Service config during terraform plan."

  permissions {
    actions = ["Microsoft.Web/sites/config/list/action"]
  }

  assignable_scopes = [data.azurerm_subscription.current.id]
}

# Granted on the dev resource group only, not the whole subscription.
resource "azurerm_role_assignment" "plan_app_service_config_read" {
  scope              = data.azurerm_resource_group.apply_dev.id
  role_definition_id = azurerm_role_definition.plan_app_service_config_read.role_definition_resource_id
  principal_id       = azuread_service_principal.github_plan.object_id
  principal_type     = "ServicePrincipal"
}