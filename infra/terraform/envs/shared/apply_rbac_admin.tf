# The apply identity holds Contributor on the dev resource group, which cannot create role
# assignments. Role Based Access Control Administrator can, so it is granted here with a
# condition that limits it to assigning and removing one built-in role: Key Vault Secrets User.
# Any other role assignment attempted by the pipeline is refused by Azure.
locals {
  key_vault_secrets_user_role_id = "4633458b-17de-408a-b874-0445c86b69e6"
}

resource "azurerm_role_assignment" "apply_rbac_admin" {
  scope                = data.azurerm_resource_group.apply_dev.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.github_apply.object_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.key_vault_secrets_user_role_id}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.key_vault_secrets_user_role_id}}
     )
    )
  EOT
}