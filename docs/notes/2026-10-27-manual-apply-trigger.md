# Manual trigger for the dev-app apply workflow

## What I built
A workflow_dispatch trigger on the dev-app apply workflow, with the apply job
restricted to the main branch.

## Why it exists
The workload stack is destroyed after each working session. The original trigger
ran only when a change under envs/dev-app was merged, so unchanged code could not
recreate the infrastructure.

## How it works
workflow_dispatch adds a Run workflow button. The apply job carries the condition
github.ref == refs/heads/main, so a run started from any other branch is skipped.
Manual runs use the same reusable workflow, concurrency group, saved-plan apply
and dev environment approval as push-triggered runs.

## What broke, and how I fixed it
Nothing failed. The guard was tested before any billable run by dispatching from
a scratch branch, where the job was skipped.

## Trade-offs
A manual run always applies the tip of main, so correctness depends on main being
reviewed. The guard prevents unreviewed branch code from being applied.

## Questions this answers in an interview
- How do you recreate ephemeral environments on demand?
- How do you stop a manual deployment trigger being used on unreviewed code?

## One-line pitch
On-demand environment rebuilds through the same gated pipeline, restricted to the
reviewed branch.