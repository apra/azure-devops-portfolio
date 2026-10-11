data "azurerm_subscription" "current" {}

data "azurerm_storage_account" "tfstate" {
  name                = "stportfoliotfstuks3b33"
  resource_group_name = "rg-portfolio-tfstate-uks-001"
}

resource "azuread_application" "github_plan" {
  display_name = "app-portfolio-github-plan"
}

resource "azuread_service_principal" "github_plan" {
  client_id = azuread_application.github_plan.client_id
}

resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.github_plan.id
  display_name   = "github-pull-requests"
  description    = "GitHub Actions runs triggered by pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:apra@112661093/azure-devops-portfolio@1390723432:pull_request"
}

resource "azurerm_role_assignment" "plan_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_plan.object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "plan_state" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_plan.object_id
  principal_type       = "ServicePrincipal"
}