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
*Status: in progress*

- [x] 3 services scaffolded with independent ownership (CODEOWNERS)
- [x] Lint (ruff) + format (black) + tests (pytest) passing on all 3 services
- [x] Path-based CI workflow written (`.github/workflows/ci.yml`)
- [ ] Branch protection enabled on `main` (PR required, 1 approval, passing CI)
- [ ] 10+ real merged PRs demonstrating the workflow

**Engineering standards applied throughout:** ruff + black enforced in CI (not
just locally), pytest with real endpoint coverage, `.env.example` documenting
required config without ever containing real secrets, Key Vault planned for
Project 2 onward for anything that is a real credential.

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
