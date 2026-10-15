# Gated Terraform apply pipeline

- Date: 2026-10-15

## What I built
A pipeline that applies Terraform to the dev environment after a merge to main. A read-only plan job saves the plan, a human approves it in a protected GitHub Environment, and a separate write identity applies exactly that plan. Login uses OIDC, so there are no stored credentials.

## Why it exists
Until now, infrastructure was applied from my laptop under my own login. That meant no second pair of eyes, no audit trail and standing write access on a personal account. In an enterprise nobody applies by hand to a shared environment.

## How it works
1. A pull request runs fmt, validate and plan under a read-only identity.
2. After merge, the plan job runs again as the read-only identity and writes the plan into the run summary.
3. The apply job runs in the dev environment, which pauses for apra-reviewer to approve. Self-review is blocked, only main can deploy, and admins cannot bypass.
4. After approval, the apply job logs in as a different identity, app-portfolio-github-apply, and applies the saved plan file. That identity has Contributor on the dev resource group only, plus access to the state blob.
5. A concurrency group stops two applies running at once.

## What broke, and how I fixed it
- I applied the network layer from my laptop before building this, which broke my own rule that every change goes through a pull request. I wrote ADR 0003 to record it as a bootstrap exception, and from now on dev changes go through the pipeline.
- My editor opened an empty buffer for the identity file, and I checked the real file with wc -c before changing anything, so I did not overwrite it.
- Review feedback showed both pipeline identities can write the whole state account, and that a public repo exposes logs and plan artifacts. Both are recorded as known risks with fixes planned.

## Trade-offs
- The shared stack (Entra identities) is still applied by hand, because creating identities needs directory permissions a pull request identity must not have.
- Actions are pinned to version tags, not commit SHAs.
- The plan artifact lives for 1 day. In a private repo this would be fine; here it is public, so Terraform must never hold secret values.

## Questions this answers in an interview
- How do you stop people applying Terraform from their laptops? (Separate identities, a pipeline that applies after merge, and no standing write access for people.)
- Why a separate identity for apply? (A pull request can run any workflow code from its branch, so the identity it can use must be read-only.)
- How does the approver know what they are approving? (The plan is written into the run summary, and the exact plan file is what gets applied.)

## One-line pitch
Terraform plans run on pull requests, and after merge a protected environment makes a human approve before a separate, least-privilege identity applies the exact reviewed plan, with no stored credentials.