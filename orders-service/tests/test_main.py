from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_returns_service_info():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "orders-service"


def test_health_returns_healthy():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_create_and_list_order():
    create_response = client.post("/orders", params={"item": "widget", "quantity": 3})
    assert create_response.status_code == 200
    created = create_response.json()
    assert created["item"] == "widget"
    assert created["quantity"] == 3

    list_response = client.get("/orders")
    assert list_response.status_code == 200
    orders = list_response.json()["orders"]
    assert any(o["item"] == "widget" for o in orders)


def test_create_order_defaults_quantity_to_one():
    response = client.post("/orders", params={"item": "gadget"})
    assert response.status_code == 200
    assert response.json()["quantity"] == 1
