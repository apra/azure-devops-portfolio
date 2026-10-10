# Terraform state storage bootstrap

- Date: 2026-10-10

## What I built
A Bash script that uses the Azure CLI to create a resource group and a
hardened storage account with a container, to hold Terraform's remote state.
It is idempotent, so running it twice is safe.

## Why it exists
Terraform records what it has built in a state file, and on a team that file
has to live somewhere shared and locked down, not on one laptop. Terraform
cannot create the storage it uses to keep its own state, because the storage
has to exist first. So the first resources are created by a script, and
everything after that is Terraform.

## How it works
- The script prints the subscription and asks for confirmation before
  changing anything, to avoid running against the wrong one.
- The storage account has TLS 1.2 as the minimum, HTTPS only, no public blob
  access, and shared key access disabled, so access goes through Entra ID
  and RBAC and there is no storage key that could leak.
- Blob versioning and 14-day soft delete allow recovery of a damaged or
  deleted state file.
- Because shared keys are off, the script grants me Storage Blob Data
  Contributor, then retries creating the container while the role takes
  effect.
- A CanNotDelete lock on the resource group protects it from accidental
  deletion, including by me as Owner.
- The storage account name is globally unique, so a short suffix derived
  from a hash of the subscription ID keeps it stable between runs.
- Terraform's azurerm backend later uses this account, and locks the state
  with a lease on the blob.

## AWS comparison
- Storage account and container: S3 and a bucket. Locking uses a blob lease
  where AWS uses a DynamoDB table.
- Role assignment: an IAM policy on a role or user. Azure grants a named
  role at a scope.
- Resource lock: termination protection, except a lock applies to everyone
  including owners.
- Resource provider registration: no AWS equivalent. Azure services are
  switched on per subscription.

## What broke, and how I fixed it
The first run created the resource group, then failed at the storage account
step with SubscriptionNotFound. I checked the subscription state and whether
Microsoft.Storage was registered, then re-ran the script, which is safe to
repeat, and it completed. [EDIT: write what you actually saw and what
cleared it.]

## Trade-offs
- These resources are not managed by Terraform, so they could drift. I
  tagged them managed-by=bootstrap-script as a deliberate exception to the
  naming ADR.
- One storage account holds state for everything. A company would use a
  dedicated management subscription and put it behind a private endpoint.
- The account uses LRS, which is cheap but keeps copies in one datacenter.
  Versioning protects against mistakes, not against losing the datacenter.
- Network access is not restricted yet: it is reachable publicly but needs
  Entra authentication. Locking it down is a possible follow-up.

## Questions this answers in an interview
- How do you handle remote state, and what about the chicken-and-egg problem?
- Why disable shared keys, and what replaces them?
- How do you protect infrastructure from accidental deletion?

## One-line pitch
I bootstrapped Terraform's remote state with an idempotent script that builds
a hardened, locked storage account using Entra-only access, so no storage
keys exist to leak.