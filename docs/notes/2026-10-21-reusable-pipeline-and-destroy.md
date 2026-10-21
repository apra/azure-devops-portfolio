# Reusable pipeline, dev-app stack and gated destroy

Date: 2026-10-21 · Issues: #38, #40

## What I built
- A second Terraform stack, `envs/dev-app`, with its own state file, that reads the foundation network through data sources and owns nothing yet.
- The apply pipeline turned into a reusable workflow (`terraform-apply-stack.yml`) with a `stack` input, called by one thin workflow per stack.
- A manual-only destroy workflow for `dev-app`, using the same reusable workflow with `destroy: true`.

## Why it exists
The foundation (resource group, VNet, subnets, NSGs) is free and should stay up. The workload (App Service plan, VM, private endpoints) costs money while it exists, so it must be destroyed daily. Separate stacks mean teardown can never touch the network, state storage or identities. One shared workflow means the plan and approval logic lives in one place.

## How it works
- Each stack has its own folder and state key (`dev.terraform.tfstate`, `dev-app.terraform.tfstate`). `dev-app` finds the foundation with `data` blocks, so it depends on it without owning it.
- PRs plan both stacks as a matrix with the read-only identity. A summary job is the single required check.
- On merge, a caller workflow (path-filtered to its own stack) calls the reusable workflow. The plan job uses the read-only identity and publishes the plan to the run summary. The apply job needs the plan job, runs in the `dev` environment (approval by a second person), and applies the exact saved plan file with the write identity.
- A reusable workflow cannot hold more permission than its caller grants, so each caller sets `id-token: write` explicitly.
- Each stack has its own concurrency group with `cancel-in-progress: false`, so two runs never touch the same state and a run is never cancelled half-way. The destroy workflow shares the `dev-app` group.
- Destroy is `workflow_dispatch` only, runs only on `main`, has the stack hardcoded, and shows a plan headed "DESTROY plan" before approval.

## What broke, and how I fixed it
Nothing failed on the first run of either piece. Before merging I checked the things most likely to go wrong: that the approval gate still works through a reusable workflow, that the path filters only trigger their own stack (the dev workflow stayed quiet when only `dev-app` changed), and that a destroy of an empty stack changes nothing outside the output. The earlier failure in this area (wrong `AZURE_CLIENT_ID` in the environment variable, AADSTS700213) is in the gated-apply note.

## Trade-offs
- Both stacks use the same `dev` environment and approvers, so approval is per environment, not per stack.
- Both identities still have blob access to the whole state account, so a pipeline run could in theory write another stack's state (recorded in ADR 0003).
- Destroy approval depends on a person actually reading the plan. The "DESTROY" heading is a prompt, not a control.
- The reusable workflow lives in the same repo, so it is not versioned independently. In Azure DevOps a central template repo can be pinned by ref.
- Teardown is manual. A scheduled destroy would run with nobody to approve it, which needs a separate decision.

## Questions this answers in an interview
- How do you structure Terraform so expensive resources can be destroyed without risking the network?
- How do you avoid copy-pasting pipelines across environments? (Reusable workflows here; `extends:` templates in Azure DevOps.)
- How do you stop two pipeline runs corrupting state?
- How do you control cost in a dev environment without doing it by hand?
- How do you make sure a destroy cannot run from an unreviewed branch or against the wrong stack?

## One-line pitch
I split Terraform into a free foundation and a billable workload, drove both through one reusable approval-gated workflow, and added a manual, guarded destroy so daily teardown follows the same controls as deployment.