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


def test_auth_endpoints_observability():
    """Verify auth endpoints attach X-Request-ID header during API lifecycle."""
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

        assert "X-Request-ID" in response.headers


def test_sensitive_data_sanitization_in_logging():
    from app.core.logging import JSONFormatter, sanitize_value
    import logging

    assert sanitize_value("password", "SecretPassword123!") == "***REDACTED***"
    assert sanitize_value("access_token", "jwt.token.val") == "***REDACTED***"
    assert sanitize_value("safe_field", "normal_value") == "normal_value"

    formatter = JSONFormatter()
    record = logging.LogRecord("titan_api", logging.INFO, "", 0, "Test log message", (), None)
    setattr(record, "password", "SuperSecret123")
    formatted = formatter.format(record)
    assert "***REDACTED***" in formatted
    assert "SuperSecret123" not in formatted


