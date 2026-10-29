# Constrained RBAC Administrator for the apply identity

## What I built
A role assignment giving the pipeline's apply identity the Role Based Access
Control Administrator role on the dev resource group, with an attribute-based
condition that limits it to assigning and removing the Key Vault Secrets User role.

## Why it exists
The apply identity held only Contributor, which cannot create role assignments.
The web app's managed identity needs a role on the vault, and the pipeline has to
create that assignment without becoming able to grant any other role.

## How it works
The condition allows role assignment writes and deletes only when the role
definition is Key Vault Secrets User. Any other role assignment attempted by the
pipeline is refused, so a compromised pipeline cannot escalate its own rights.
The layer that defines the pipeline's identities is applied manually from merged
code, because the pipeline cannot manage its own permissions; this is recorded in
ADR 0003.

## What broke, and how I fixed it
The manual apply returned 403 AuthorizationFailed with the message that the
caller had an authorisation whose ABAC condition was not fulfilled. The
administrator account's own Owner assignment carried a condition excluding the
privileged administrator roles, and the role being assigned was one of them. The
personal Owner account removed that one identifier from the condition, the apply
succeeded, and the condition was restored. The resulting assignment and its
condition were verified, and the pipeline later created the web app's role
assignment successfully.

## Trade-offs
A manual step remains for the identity layer. Moving it to a separately gated
pipeline with its own privileged identity is a backlog item.

## Questions this answers in an interview
- How do you let a pipeline create role assignments without giving it Owner?
- What are ABAC conditions on role assignments, and why do they matter?
- How do you bootstrap the identities a pipeline runs as?

## One-line pitch
A pipeline that can wire one specific role and nothing more, with the bootstrap
layer applied from reviewed code and the exception recorded.