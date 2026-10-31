# Identity used by Azure Pipelines to deploy the application to the dev web app.
# Azure DevOps presents a federated token for the service connection, so no secret exists.
resource "azuread_application" "azdo_deploy" {
  display_name = "sp-azdo-deploy-portfolio-dev"
}

resource "azuread_service_principal" "azdo_deploy" {
  client_id = azuread_application.azdo_deploy.client_id
}

# Trusts tokens issued for exactly one Azure DevOps service connection.
resource "azuread_application_federated_identity_credential" "azdo_deploy" {
  application_id = azuread_application.azdo_deploy.id
  display_name   = "azdo-sc-azure-portfolio-dev"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://login.microsoftonline.com/0d041759-eed4-467e-a540-4f737cdc6878/v2.0"
  subject        = "/eid1/c/pub/t/WRcEDdTufkalQE9zfNxoeA/a/rISbSSETf0KqFyZ8ppdXmA/sc/f933cda1-0e9b-4e48-8462-c3a5d77330a5/45dc9c73-b52a-463c-aeac-cfaa7ea2adba"
}

# Deploy to web apps and manage nothing else, on the dev resource group only.
resource "azurerm_role_assignment" "azdo_deploy_website_contributor" {
  scope                = data.azurerm_resource_group.apply_dev.id
  role_definition_name = "Website Contributor"
  principal_id         = azuread_service_principal.azdo_deploy.object_id
  principal_type       = "ServicePrincipal"
}

# Read access on the same group, so the service connection can be verified.
resource "azurerm_role_assignment" "azdo_deploy_reader" {
  scope                = data.azurerm_resource_group.apply_dev.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.azdo_deploy.object_id
  principal_type       = "ServicePrincipal"
}

output "azdo_deploy_client_id" {
  description = "Application (client) ID for the Azure DevOps service connection"
  value       = azuread_application.azdo_deploy.client_id
}