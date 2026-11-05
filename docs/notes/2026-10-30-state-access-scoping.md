# Scoping pipeline access to the Terraform state container

## What I built
The plan and apply identities previously held Storage Blob Data Contributor on
the whole state storage account. Both assignments were replaced with the same
role scoped to the `tfstate` container, which is the narrowest scope that still
supports Terraform's state operations.

## Why it exists
Least privilege applies to the data plane as much as to resource management. A
storage account scope would also cover any other container added later. The
state container holds the infrastructure's complete description, including
resource identifiers, so access to it is limited to what the pipelines need.

## How it works
- A local value in the shared stack builds the container's resource identifier
  from the storage account identifier.
- Both role assignments point at that identifier. Changing the scope of a role
  assignment forces replacement, so each assignment is deleted and recreated.
- The plan identity keeps write access. Terraform takes a lease on the state
  blob to lock state, even during a plan, and acquiring a lease is a write
  operation.

## What broke, and how I fixed it
1. **Delete refused by a resource lock.** The state resource group carries a
   CanNotDelete lock. Deleting the old role assignments returned `ScopeLocked`.
   The lock was recorded, removed for the duration of the apply, recreated with
   the same name and level, and its presence verified. The step is logged in
   ADR 0003.
2. **Stale state lock.** A failed first apply left a Terraform lock on the state
   blob. After confirming that no Terraform process was running, the lock was
   released with `terraform force-unlock` using the identifier from the error.
   Locking was never disabled.
3. **Process lesson.** A chained block of commands continued past a failure and
   recreated the resource lock before the apply had completed. Destructive and
   verification steps are now run individually, and each result is checked
   before the next step.

## Trade-offs
- Container scope is narrower than account scope but is still not per stack. Each
  stack could have its own container and identity, which would limit the effect
  of a compromised plan identity. That is deferred.
- The delete lock protects the state from accidental removal but also blocks
  legitimate role changes, so each change needs a recorded, temporary exception.
- `force-unlock` is safe only after confirming that no process holds the lock.
  Forcing it while an apply is running risks state corruption.

## Questions this answers in an interview
- How do you restrict access to Terraform state, and at what scope?
- Why does a plan need write access to state?
- What do you do about a stale state lock, and when is it unsafe?
- How do resource locks interact with infrastructure as code?
- What changes when a role assignment's scope changes?

## One-line pitch
The pipeline identities access only the state container, with the lock and
force-unlock behaviour understood and exceptions recorded.
