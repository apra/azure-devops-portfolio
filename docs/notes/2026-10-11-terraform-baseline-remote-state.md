# Terraform baseline and remote state

- Date: 2026-10-11

## What I built
A Terraform configuration for a dev environment: the azurerm provider with
pinned versions, a backend pointing at the storage account from the bootstrap
script, and a first resource group. I ran init, plan and apply, and the state
now lives in a blob in Azure, not on my laptop.

## Why it exists
Infrastructure as code makes changes reviewable, repeatable and auditable.
Remote state means a team shares one record of what exists, with locking so
two people cannot change the same infrastructure at once.

## How it works
- versions.tf pins the Terraform and provider versions and declares an empty
  azurerm backend, so the file holds nothing environment-specific.
- backend.hcl supplies the storage account, container and state key, and sets
  use_azuread_auth because shared keys are disabled.
- main.tf defines the four required tags once as a local value and a
  resource group named under ADR 0002.
- The subscription ID comes from the ARM_SUBSCRIPTION_ID environment variable,
  so no ID is committed.
- I ran plan with -out and applied that saved plan, so apply runs exactly what
  I reviewed. A second plan reported no changes.
- The lock file is committed to pin the provider version. State and plan
  files are ignored, because they can contain sensitive values.

## AWS comparison
- The azurerm backend is the equivalent of the S3 backend with DynamoDB
  locking. Azure locks with a lease on the state blob.
- plan and apply behave the same as on AWS. CloudFormation's nearest idea is
  a change set.
- The aws provider has default_tags. The azurerm provider does not.

## What broke, and how I fixed it
- ADR 0002 claimed provider default tags would cover tagging. That is not
  true for azurerm, so I corrected the ADR and used a shared local tags map.
- main.tf was missing when I went to run init, because I had not saved it.
  Checking file sizes before running anything caught it.

## Trade-offs
- Each environment has its own state key, so a mistake in dev cannot touch
  prod state.
- The state account is hardened but still reachable on the public internet
  with Entra authentication. A private endpoint would close that.
- State can contain sensitive values, so access to the storage account
  matters as much as access to the code.

## Questions this answers in an interview
- What is Terraform state, and why keep it remote?
- What is the difference between plan and apply, and why apply a saved plan?
- How do you keep secrets out of a Terraform repo?

## One-line pitch
I set up Terraform with locked remote state and a reviewed plan-then-apply
flow, with no subscription ID or secrets committed to the repo.