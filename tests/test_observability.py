"""
Unit and integration tests for FastAPI backend observability, health, and authentication endpoints.
"""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "X-Request-ID" in response.headers


def test_ready_endpoint():
    response = client.get("/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
    assert "X-Request-ID" in response.headers


def test_request_id_preservation():
    custom_id = "test-custom-request-id-12345"
    response = client.get("/health", headers={"X-Request-ID": custom_id})
    assert response.status_code == 200
    assert response.headers["X-Request-ID"] == custom_id


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert "X-Request-ID" in response.headers


def test_auth_placeholder_endpoints():
    endpoints = [
        ("POST", "/api/v1/auth/register"),
        ("POST", "/api/v1/auth/login"),
        ("POST", "/api/v1/auth/refresh"),
        ("POST", "/api/v1/auth/logout"),
        ("GET", "/api/v1/auth/me"),
    ]

    for method, path in endpoints:
        if method == "POST":
            response = client.post(path)
        else:
            response = client.get(path)

        assert response.status_code == 501
        data = response.json()
        assert data["success"] is False
        assert data["error"] == "NotImplemented"
        assert data["message"] == "Endpoint not implemented yet."
        assert "X-Request-ID" in response.headers
