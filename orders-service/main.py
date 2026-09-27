"""
orders-service
A minimal FastAPI app. This is deliberately simple — the app itself
isn't the point of the project, it's a prop for the DevOps tooling
(pipelines, containers, deployments, monitoring) built around it.
"""

from datetime import UTC, datetime

from fastapi import FastAPI

app = FastAPI(title="orders-service")

SERVICE_NAME = "orders-service"
SERVICE_VERSION = "0.1.0"

# In-memory "database" — good enough for a DevOps prop app.
# Swapped for a real Azure SQL/Cosmos DB connection in Project 2.
ORDERS = {}
_next_id = 1


@app.get("/")
def root():
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "message": "orders-service is running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "timestamp": datetime.now(UTC).isoformat(),
    }


@app.get("/orders")
def list_orders():
    return {"orders": list(ORDERS.values())}


@app.post("/orders")
def create_order(item: str, quantity: int = 1):
    global _next_id
    order = {"id": _next_id, "item": item, "quantity": quantity}
    ORDERS[_next_id] = order
    _next_id += 1
    return order


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
