from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_returns_service_info():
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "auth-service"


def test_health_returns_healthy():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_login_with_credentials_returns_token():
    response = client.post("/login", params={"username": "alice", "password": "hunter2"})
    assert response.status_code == 200
    body = response.json()
    assert body["username"] == "alice"
    assert "token" in body


def test_login_without_password_returns_error():
    response = client.post("/login", params={"username": "alice", "password": ""})
    assert response.status_code == 200
    assert "error" in response.json()


def test_version_returns_service_and_version():
    response = client.get("/version")
    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "auth-service"
    assert body["version"] == "0.1.0"