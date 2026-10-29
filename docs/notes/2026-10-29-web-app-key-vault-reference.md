# Web app access to Key Vault with a Key Vault reference

## What I built
A Key Vault Secrets User role assignment for the web app's system-assigned
managed identity, scoped to the vault, and an app setting that references a vault
secret.

## Why it exists
The application needs a secret at runtime with no credential in code, settings
or Terraform state.

## How it works
App Service resolves the reference value (a secret URI without a version) using
the app's own identity and exposes it as an ordinary environment variable.
Resolution works over the private path: VNet integration, the private endpoint
and the private DNS zone. The secret value never appears in Terraform; only its
address does.

## What broke, and how I fixed it
Nothing failed. I expected that route-all might be needed for the platform to
reach a network-restricted vault; the reference resolved without it. Seeding the
test secret needed a temporary firewall rule and a temporary Secrets Officer
assignment, both removed immediately and recorded in ADR 0003.

## Trade-offs
The role is read-only and scoped to the vault, not the resource group. Seeding
secrets by hand is acceptable for a test value and not for production.

## Questions this answers in an interview
- How does an App Service read a secret without a stored credential?
- Why assign the role at the vault scope and not the resource group?
- How do you check that a Key Vault reference actually resolved?

## One-line pitch
A web app that reads a secret from a private vault using only its own identity,
with nothing sensitive in code or state.