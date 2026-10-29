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

## Exceptions log, October 2026

Each entry is a change made outside the gated pipeline, with the reason and the follow-up.

### 2026-10-23: manual deletion of the dev-app web app and plan
The gated destroy could not run: the plan identity (Reader) cannot perform
`Microsoft.Web/sites/config/list/action`, which Terraform needs to refresh a web app in state.
The local Azure CLI sign-in was also blocked by Entra security defaults. To stop billing,
the web app and App Service plan were deleted in the portal. State was left as is; the next
plan treats both as missing. Follow-up: Issue 47.

### 2026-10-24: shared stack applied manually from the Issue 47 branch
The custom role `Portfolio Plan - App Service Config Reader` (one action) and its assignment
to the plan identity on the dev resource group were applied by hand before merge, as with
earlier shared-stack changes, because the shared stack manages the pipeline identities themselves.
Trade-off: the plan identity can now read App Service configuration, which can include app
settings. Mitigation: no secret values in app settings, Key Vault references only. Pull request
workflows run with the plan identity from the branch's own workflow file, so workflow changes
need extra review.

### 2026-10-24: dedicated admin identity and its state access
Entra security defaults require MFA for Azure CLI and the portal and block device code flow.
The personal Microsoft account used until now could not satisfy this for the CLI. A cloud-only
admin user was created in the tenant (Global Administrator; Owner on the subscription with a
condition that excludes assigning Owner, User Access Administrator and RBAC Administrator),
with Microsoft Authenticator registered. It was given Storage Blob Data Contributor on the
`tfstate` container only, by hand, because Owner does not include blob data access.
Follow-ups: bring the admin's state access into the bootstrap script or shared stack; reduce
Global Administrator to narrower roles once bootstrap work is done; use browser sign-in
(`core.enable_broker_on_windows=false`), never device code.

### 29 October 2026: RBAC Administrator for the apply identity (#78)
The shared stack is applied manually, as a bootstrap exception, because it
manages the identities the pipeline itself uses. The apply identity is granted
Role Based Access Control Administrator on the dev resource group, constrained
by a condition to assigning and removing only the Key Vault Secrets User role.
This allows the workload stack to grant its web app identity read access to the
vault without giving the pipeline general role-assignment rights.
The apply is performed from the merged main branch.