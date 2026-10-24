# Plan identity gap and the security defaults sign-in block

Date: 2026-10-24 · Issues: #47

## What I built
A custom Azure role with one permission, `Microsoft.Web/sites/config/list/action`, assigned to the read-only plan identity on the dev resource group. Also a dedicated MFA-protected admin user for running Terraform from my laptop.

## Why it exists
Terraform refreshes every resource in state before planning. For a Linux web app that refresh calls the list-config action, which the built-in Reader role does not include. Once the web app was in state, every plan of the stack failed with a 403, including the gated destroy.

## How it works
The role holds exactly that one action and is assigned only on the dev resource group, so the plan identity stays read-only everywhere else. It was applied from the shared stack by hand because that stack manages the pipeline identities themselves.

## What broke, and how I fixed it
- **Plan identity 403:** the destroy workflow failed at plan with AuthorizationFailed. Cause: Reader cannot list web app config. Fix: custom role above.
- **Sign-in blocked:** after the Azure CLI session expired, every sign-in failed with error 530035. The Entra sign-in log said "blocked by security defaults" and single-factor authentication. Security defaults require MFA for the CLI and the portal, and my identity was a personal Microsoft account the tenant could not treat as MFA-registered.
- **Wrong turn, mine:** I tried device code login. Security defaults block device code flow outright, so that could never work. The Windows account broker window also froze, so I turned the broker off and used the normal browser sign-in.
- **Fix:** created a cloud-only admin user, registered Authenticator, signed in with the browser flow. The state backend then returned 403 because Owner has no blob data access, so I granted Storage Blob Data Contributor on the container only.
- **Cost control:** the gated destroy was blocked, so I deleted the billable resources in the portal as a documented one-off exception.

## Trade-offs
- The plan identity can now read app settings through that action. Mitigated by keeping secrets out of app settings.
- The admin user is highly privileged. It needs MFA, narrower roles later, and use only for admin work.
- Manual steps are recorded in ADR 0003 rather than hidden.

## Questions this answers in an interview
- Why can a Reader fail to run `terraform plan`, and how do you fix it without over-granting?
- Management plane versus data plane permissions in Azure.
- What are Entra security defaults, and why did they block the CLI?
- Why not just disable security defaults?
- How do you control cost when the pipeline is unavailable?

## One-line pitch
I found that Reader cannot refresh an App Service, added a single-action custom role scoped to one resource group, and fixed a security-defaults sign-in block by adding MFA instead of weakening the tenant.