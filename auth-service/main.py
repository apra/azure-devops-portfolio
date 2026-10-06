"""
auth-service
A minimal FastAPI app. This is deliberately simple — the app itself
isn't the point of the project, it's a prop for the DevOps tooling
(pipelines, containers, deployments, monitoring) built around it.
"""

from datetime import UTC, datetime

from fastapi import FastAPI

app = FastAPI(title="auth-service")

SERVICE_NAME = "auth-service"
SERVICE_VERSION = "0.1.0"


@app.get("/")
def root():
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "message": "auth-service is running",
    }


@app.get("/health")
def health():
    """
    Used by: deployment smoke tests (Project 3), Kubernetes liveness/
    readiness probes (Project 5), and uptime checks (Project 6).
    Keep this endpoint fast and dependency-free so it reflects whether
    THIS process is healthy, not whether its downstream dependencies are.
    """
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "timestamp": datetime.now(UTC).isoformat(),
    }

@app.get("/version")
def version():
    """
    Report which version of the service is running. Used to confirm a
    deployment rolled out the expected version.
    """
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
    }


@app.post("/login")
def login(username: str, password: str):
    """
    Fake auth endpoint — no real logic, just enough of a contract
    for other services / smoke tests to call against.
    """
    if username and password:
        return {"token": "fake-jwt-token-for-demo-purposes", "username": username}
    return {"error": "username and password required"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
