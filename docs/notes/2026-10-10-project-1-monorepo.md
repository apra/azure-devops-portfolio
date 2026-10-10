# Project 1: Multi-team monorepo with governed contribution

- Date: 2026-10-10

## What I built
A single GitHub repo holding three small Python (FastAPI) services, with a
locked-down main branch. Every change goes through a pull request, automated
checks (lint, format, tests) and a review from a second account before it can
merge.

## Why it exists
In a shared repo, one bad change can break every team. The goal was to
simulate that environment: nobody pushes straight to main, each service has
an owner, and automation checks each change before a human reviews it.

## How it works
- A GitHub Actions workflow detects which service folders changed and runs
  ruff, black and pytest only for those services.
- A final "CI Summary" job always runs and reports one stable status. That
  job is the required check in the branch ruleset, because skipped jobs
  don't report a result and can't be required directly.
- The ruleset on main requires a PR, one approval, a passing CI Summary,
  and blocks force pushes and deletions.
- CODEOWNERS routes review requests, and a PR template requires a linked
  Issue.
- Commits are signed with an SSH key, and a second GitHub account
  (apra-reviewer) approves PRs, since GitHub won't let an author approve
  their own.
- Design decisions are recorded in ADRs under docs/adr.

## What broke, and how I fixed it
- Pushing over HTTPS failed because GitHub no longer accepts passwords.
  I switched to SSH keys, and reused the same key for commit signing.
- PR #5 failed CI on the black format check: one missing blank line and a
  missing newline at the end of a file. I had only run the tests locally,
  not all three checks. I ran black, pushed a fix to the same branch, and
  the gate let it through. I wrote this up as an incident note in the README.
- I clicked plain Merge instead of Squash on PR #1. Nothing broke, but I
  later restricted merging to squash-only so it can't happen again.

## Trade-offs
- One repo makes shared rules easy to enforce, but it means the change
  detection is a point of failure: if it misreports, checks