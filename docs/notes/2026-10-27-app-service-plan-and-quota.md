# App Service plan and the zero-quota incident

## What I built
A Linux B1 App Service plan and a Python 3.12 web app (HTTPS only, TLS 1.2, FTP
disabled, system-assigned managed identity) in the workload stack.

## Why it exists
It is the target for the private networking, Key Vault and pipeline work. The plan
is the billed resource, not the web app: stopping the app does not stop billing.

## How it works
The plan defines the compute tier and is billed per hour. VNet integration and
private endpoints require Basic tier or above; deployment slots require Standard.

## What broke, and how I fixed it
The first apply failed because the subscription had a quota of zero for B1 plans.
The quota page reported the free subscription as ineligible for adjustment.
Upgrading to pay-as-you-go made the quota request available and it was granted.

## Trade-offs
A pay-as-you-go subscription has no spending limit, so cost control rests on the
daily teardown and a budget alert, which only sends email.

## Questions this answers in an interview
- What is the difference between an App Service plan and a web app?
- How do you handle a quota error?
- Which App Service features need which tiers?

## One-line pitch
Found and resolved a subscription quota block, and designed around the billing
model with daily teardown.