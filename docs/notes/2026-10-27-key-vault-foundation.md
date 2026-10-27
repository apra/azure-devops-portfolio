# Key Vault with RBAC authorisation

## What I built
An Azure Key Vault in the foundation stack with RBAC authorisation, purge
protection, 7-day soft delete retention and a deny-by-default network ACL.

## Why it exists
Application and pipeline secrets are held in Key Vault and referenced at runtime,
so no secret values appear in code or Terraform state.

## How it works
Access is granted through Azure role assignments rather than vault access
policies. The management plane and data plane are separate: an Owner can manage
the vault but cannot read secrets without a data-plane role. The vault sits in the
foundation stack so it persists when the workload stack is destroyed.

## What broke, and how I fixed it
Nothing failed. Design decision: soft delete retention cannot be changed after
creation, and purge protection prevents permanent deletion during retention, so a
vault inside the daily-destroyed stack would conflict with its own name on
recreation. Placing it in the persistent stack avoids that, and 7 days limits how
long the name is reserved at the end of the project.

## Trade-offs
Purge protection and the minimum retention suit a lab; production would use 90
days. The private endpoint and role assignments follow in separate changes.

## Questions this answers in an interview
- RBAC versus access policies in Key Vault?
- What do soft delete and purge protection protect against?
- Why separate the management plane from the data plane?

## One-line pitch
A production-configured vault in the persistent stack, with access granted
through RBAC and no secrets in code.