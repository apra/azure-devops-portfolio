"""
notifications-service
A minimal FastAPI app. This is deliberately simple — the app itself
isn't the point of the project, it's a prop for the DevOps tooling
(pipelines, containers, deployments, monitoring) built around it.
"""

from datetime import UTC, datetime

from fastapi import FastAPI

app = FastAPI(title="notifications-service")

SERVICE_NAME = "notifications-service"
SERVICE_VERSION = "0.1.0"

SENT_NOTIFICATIONS = []


@app.get("/")
def root():
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "message": "notifications-service is running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "timestamp": datetime.now(UTC).isoformat(),
    }


@app.post("/notify")
def send_notification(recipient: str, message: str):
    """
    Fake notification send — logs to an in-memory list instead of
    actually emailing/texting anyone. Good enough for pipeline and
    monitoring demos (Project 6's alert → work item loop can call this).
    """
    entry = {
        "recipient": recipient,
        "message": message,
        "sent_at": datetime.now(UTC).isoformat(),
    }
    SENT_NOTIFICATIONS.append(entry)
    return entry


@app.get("/notifications")
def list_notifications():
    return {"notifications": SENT_NOTIFICATIONS}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
