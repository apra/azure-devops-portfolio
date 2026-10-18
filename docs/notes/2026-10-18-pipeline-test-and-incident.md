# Pipeline test and incident: wrong client ID in the environment

- Date: 2026-10-18

## What I built
A first end-to-end run of the approval-gated Terraform apply pipeline, using a one-line change: a tag on the dev resource group. The run planned as the read-only identity, paused for approval, and applied as a separate write identity.

## Why it exists
A pipeline that has never run is a guess. A small real change proves the whole path before the bigger infrastructure layers depend on it.

## How it works
Merge to main triggers the workflow. The plan job logs in as the plan identity and saves the plan. The apply job runs in the dev environment, waits for apra-reviewer, then logs in as the apply identity via OIDC and applies the exact saved plan.

## What broke, and how I fixed it
The apply job failed at login with AADSTS700213 (no matching federated identity record). The subject in the error was exactly the subject in the trust rule, so the rule was not the problem. The environment variable AZURE_CLIENT_ID held the wrong client ID, so the job logged in as an identity that had no trust rule for the dev environment. I compared the variable against the IDs from Entra, corrected it, re-ran only the failed job, approved again, and it applied. I then checked the tag in Azure directly.

## Trade-offs
Two similar-looking client IDs (plan and apply) are easy to mix up. Next time I would put the ID in the Terraform output with a clear name, and check both values against Entra before the first run.

## Questions this answers in an interview
- A federated login fails with AADSTS700213. How do you debug it? (Compare the presented subject with the trust rule; if they match, check which client ID the job actually used.)
- How do you know a pipeline change really reached Azure? (Verify in Azure independently, not just a green job.)
- Why re-run only the failed job? (The successful plan job's saved plan is reused, and Terraform refuses to apply it if state has changed.)

## One-line pitch
I proved the gated apply pipeline with a real change, and debugged a failed federated login by checking which identity the job had actually used.# <Piece name>

- Date:

## What I built
Two or three sentences.

## Why it exists
The problem it solves, in plain words.

## How it works
The key parts, in the order they fit together.

## What broke, and how I fixed it
The real problems, including the dead ends.

## Trade-offs
What I would do differently, and what I deliberately left out.

## Questions this answers in an interview
Two or three, written the way an interviewer would ask them.

## One-line pitch
One sentence I can say out loud without notes.
