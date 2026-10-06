# Platform Monorepo — Azure DevOps Engineering Portfolio

A single, evolving repo built to demonstrate real, hands-on Azure DevOps
Engineer skills: CI/CD pipeline design, Infrastructure as Code, GitOps,
DevSecOps, and observability — built and grown project by project rather
than filled in from a tutorial.

## Why one repo

Each project below builds on the infrastructure and services from the
last, the way a real platform accumulates capability over time, rather
than existing as disconnected demos.

## Services

Three independently-owned services simulate a multi-team monorepo:

| Service | Port | Owner (simulated) |
|---|---|---|
| `auth-service` | 8000 | @auth-team-owner |
| `orders-service` | 8001 | @orders-team-owner |
| `notifications-service` | 8002 | @notifications-team-owner |

Each is a minimal FastAPI app — deliberately simple, since the app is a
prop for the DevOps tooling, not the deliverable.

## Running a service locally

```bash
cd auth-service
pip install -r requirements.txt
python main.py
# or: uvicorn main:app --reload --port 8000
```

Then hit `http://localhost:8000/` and `http://localhost:8000/health`.

## Running with Docker

```bash
cd auth-service
docker build -t auth-service .
docker run -p 8000:8000 auth-service
```

## Project log

This section grows as each project is completed — a running record of
what was built, what broke, and what was learned.

### Project 1 — Multi-team monorepo with governed contribution
*Status: nearly complete*

- [x] 3 services scaffolded with independent ownership (CODEOWNERS)
- [x] Lint (ruff) + format (black) + tests (pytest) passing on all 3 services
- [x] Path-based CI workflow written (`.github/workflows/ci.yml`)
- [x] Ruleset on `main`: PR required, approval required, CI Summary required, force pushes and deletions blocked
- [x] Gate proven: PR #5 was blocked by failing CI and merged only after the fix (see incident log below)
- [x] Design decision recorded: `docs/adr/0001-monorepo-with-path-based-ci.md`
- [ ] Replace the `dorny/paths-filter` action with an in-repo change-detection script (deferred)

**Engineering standards applied throughout:** ruff + black enforced in CI (not
just locally), pytest with real endpoint coverage, `.env.example` documenting
required config without ever containing real secrets, Key Vault planned for
Project 2 onward for anything that is a real credential.

#### Incident log: black formatting failure on PR #5 (2026-10-06)

**What happened:** PR #5 added a `/version` endpoint to `auth-service`. The
`auth-service` CI job failed at the black format check, so `CI Summary`
failed and the ruleset blocked the merge.

**Cause:** two formatting issues in the new code: one blank line instead of
two before the new function, and no newline at the end of the test file.
Locally I had only confirmed pytest passed, so the formatting problems were
not caught before pushing.

**Detection:** the required `CI Summary` check, before any review approval.

**Fix:** ran `black` locally, reviewed the diff, and pushed a follow-up
commit to the same branch. CI re-ran and passed; the PR was then approved
and squash-merged.

**Lesson:** run the full check set (ruff, black, pytest) locally before
pushing, not just the tests. A pre-commit hook would enforce this
automatically and is a possible follow-up.

### Project 2 — Infra you can't tear down
*Status: not started*

### Project 3 — CI/CD with a deployment you can break
*Status: not started*

### Project 4 — Security as a gate, not a checkbox
*Status: not started*

### Project 5 — GitOps you don't manually deploy
*Status: not started*

### Project 6 — Observability that actually tells you something
*Status: not started*

### Project 7 — Same pipeline, different engine (Jenkins)
*Status: not started*
