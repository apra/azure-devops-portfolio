# ADR 0001: Monorepo with path-based CI

- Status: Accepted
- Date: 2026-10-06

## Context

This repo holds three services (auth, orders, notifications) that simulate
separate teams. I needed a structure where each service can be changed and
tested independently, while changes stay reviewable in one place.

## Decision

Keep all services in one repository, and run CI per service based on which
paths changed in a pull request. A final "CI Summary" job aggregates the
results, and that single job is the required status check in the branch
ruleset on main.

## Alternatives considered

- One repo per service: stronger isolation, but more repos to configure, and
  shared rules (branch protection, CODEOWNERS, PR template) would need
  repeating in each one.
- Run every service's checks on every PR: simplest to build, but slow and
  wasteful as the number of services grows, and unrelated failures would
  block unrelated changes.

## Consequences

- Positive: one place to enforce review and CI rules; a change to one
  service does not trigger the others' checks.
- Negative: the change-detection logic is a point of failure. If it
  misreports, checks are skipped when they should have run. For that reason
  the plan is to make unknown cases default to running everything.
- Negative: required checks must be a single stable name, because jobs that
  are skipped do not report a result. That is why CI Summary exists.

## Notes

Change detection currently uses a marketplace action (dorny/paths-filter).
Replacing it with an in-repo script is a possible follow-up.