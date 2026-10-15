# 0003. Gated Terraform apply, and the bootstrap exceptions

- Status: Accepted
- Date: 2026-10-15

## Context
Until now, `terraform apply` was run from a laptop. That breaks the standard
that every change goes through a pull request, CI and a second reviewer.

## Decision
Infrastructure is applied by a pipeline, not by people.

- Plans run on pull requests under a read-only identity.
- After merge to `main`, `.github/workflows/terraform-apply.yml` runs a `plan`
  job (read-only identity) and an `apply` job.
- The `apply` job runs in the GitHub Environment `dev`. It needs approval from
  `apra-reviewer`, prevents self-review, only runs from `main`, and admins
  cannot bypass it.
- The `apply` job uses a separate identity, `app-portfolio-github-apply`, with
  Contributor on `rg-portfolio-dev-uks-001` only and blob access to the state
  account. Login uses OIDC, so there are no stored credentials.
- The exact plan file that was shown to the approver is the one that is applied.

## Bootstrap exceptions
These were applied by hand from a laptop, because the pipeline could not exist
before them:

- The Terraform state storage account (bootstrap script).
- The `dev` resource group and the dev network (VNet, subnets, NSGs). Applied
  locally before this pipeline existed.
- The `shared` stack (Entra identities and their role assignments). It stays a
  manual apply: it needs directory permissions that a pull-request identity
  must not have.

From this point, changes to `envs/dev` are applied by the pipeline only.

## Known risks, accepted for now
- Both pipeline identities have Storage Blob Data Contributor on the whole state
  account, so they can write other stacks' state. Mitigated by blob versioning,
  14-day soft delete and a delete lock. To fix: scope each identity to its own
  state blob.
- Pull-request workflows run the branch's own workflow file, so anyone who can
  push a branch can use the plan identity. Mitigated by a two-person team and by
  fork pull requests not receiving cloud tokens.
- The plan file is uploaded as an artifact for 1 day. It may hold sensitive
  values once Key Vault is in use. Rule: Terraform never sets secret values.
- The OIDC subject strings are matched exactly and proven by the first run.
- Actions are pinned to version tags, not commit SHAs.
- The state storage and resource group names are written directly in the shared
  stack and should become variables.
- The repository is public, so run logs, plan summaries and artifacts are visible to anyone. No secret values may ever be in Terraform state or plans.

## Consequences
Every dev change gets a reviewed pull request, a visible plan, a human approval
and an audit trail. Changes to shared modules outside `envs/dev` will need their
paths added to the workflow trigger.