from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_returns_service_info():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "notifications-service"


def test_health_returns_healthy():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_send_and_list_notification():
    send_response = client.post(
        "/notify", params={"recipient": "bob@example.com", "message": "Order shipped"}
    )
    assert send_response.status_code == 200
    sent = send_response.json()
    assert sent["recipient"] == "bob@example.com"
    assert "sent_at" in sent

    list_response = client.get("/notifications")
    assert list_response.status_code == 200
    notifications = list_response.json()["notifications"]
    assert any(n["recipient"] == "bob@example.com" for n in notifications)
