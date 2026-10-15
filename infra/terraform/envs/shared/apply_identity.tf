# Identity used by the terraform-apply workflow. Separate from the plan identity:
# the plan identity (pull_request) is read-only, this one can write, but only
# inside the dev resource group, and only when the "dev" environment is approved.

data "azurerm_resource_group" "apply_dev" {
  name = "rg-portfolio-dev-uks-001"
}

data "azurerm_storage_account" "apply_tfstate" {
  name                = "stportfoliotfstuks3b33"
  resource_group_name = "rg-portfolio-tfstate-uks-001"
}

resource "azuread_application" "github_apply" {
  display_name = "app-portfolio-github-apply"
}

resource "azuread_service_principal" "github_apply" {
  client_id = azuread_application.github_apply.client_id
}

# Trust GitHub's token only when the job runs in the "dev" environment, which
# is the job that needs the reviewer's approval.
resource "azuread_application_federated_identity_credential" "github_apply_dev" {
  application_id = azuread_application.github_apply.id
  display_name   = "github-environment-dev"
  description    = "terraform-apply job running in the dev environment"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:apra@112661093/azure-devops-portfolio@1390723432:environment:dev"
}

resource "azurerm_role_assignment" "apply_dev_contributor" {
  scope                = data.azurerm_resource_group.apply_dev.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_apply.object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "apply_state_blob" {
  scope                = data.azurerm_storage_account.apply_tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_apply.object_id
  principal_type       = "ServicePrincipal"
}

output "apply_client_id" {
  description = "Client ID for the AZURE_CLIENT_ID variable in the dev environment"
  value       = azuread_application.github_apply.client_id
}

# Lets the read-only plan identity run the "plan" job of the apply workflow
# after a merge to main. Still read-only: no write role is attached to it.
resource "azuread_application_federated_identity_credential" "github_plan_main" {
  application_id = azuread_application.github_plan.id
  display_name   = "github-main-branch"
  description    = "Read-only plan job after merge to main (terraform-apply workflow)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:apra@112661093/azure-devops-portfolio@1390723432:ref:refs/heads/main"
}