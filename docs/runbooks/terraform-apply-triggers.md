# Runbook: Terraform Apply (dev-app) triggers and approval

## Purpose
States when the apply workflow for the workload stack starts, what protects it,
and what to do when it starts at an inconvenient time.

## Trigger rules
The workflow `Terraform Apply (dev-app)` starts in two cases:
1. A push to `main` that changes any file under `infra/terraform/envs/dev-app/`.
   A squash merge of a pull request that touches that path is such a push.
2. A manual dispatch from the `main` branch.

A job-level condition limits execution to `main`. It does not limit the trigger.

## Protection
- The plan job runs first with the read-only identity and makes no changes.
- The apply job is behind the `dev` environment. It pauses until `apra-reviewer`
  approves, and it uses the apply identity only after approval.
- Runs of this workflow share one concurrency group and are not cancelled by
  later runs.

## Behaviour to expect
- Merging a change to the workload stack always starts a run that waits for
  approval. This happens even when the intention is to apply the change at the
  next session.
- A pending run blocks the destroy workflow for the same stack, which queues
  behind it until the apply run finishes or is cancelled.

## Procedure
1. Open the run and read the plan, in particular any `forces replacement` line.
2. If the change should be applied now, approve the run.
3. If it should not be applied now, for example because the session's workload
   is running and a replacement would remove it, cancel the run or reject the
   deployment. No resource is changed.
4. A cancelled run does not undo the merge. The change is applied by dispatching
   the workflow at the next session.

## History
- 2 November 2026: merging the change that installs `zip` on the agent (#96)
  started a run. The change was expected to replace the agent VM. The run was cancelled
  before any change, and the destroy workflow then ran normally.
