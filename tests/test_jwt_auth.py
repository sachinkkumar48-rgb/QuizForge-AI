"""
Unit and integration tests for JWT Authentication, Passwords, and Protected Endpoints.
"""
from datetime import timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.identity.token_service import TokenService

client = TestClient(app)


def test_register_and_login_jwt_flow():
    # Register new user
    user_data = {
        "email": "jwt_test_user@example.com",
        "password": "SecurePassword123!",
        "full_name": "JWT Test User",
    }
    response = client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 201
    token_data = response.json()
    assert "access_token" in token_data
    assert "refresh_token" in token_data
    assert token_data["token_type"] == "bearer"

    access_token = token_data["access_token"]

    # Verify /me with valid Bearer token
    me_response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response.status_code == 200
    user_info = me_response.json()
    assert user_info["email"] == "jwt_test_user@example.com"
    assert user_info["full_name"] == "JWT Test User"

    # Login with user credentials
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "jwt_test_user@example.com", "password": "SecurePassword123!"},
    )
    assert login_response.status_code == 200
    login_token_data = login_response.json()
    assert "access_token" in login_token_data
    assert login_token_data["token_type"] == "bearer"


def test_invalid_jwt_returns_401():
    invalid_token = "invalid.jwt.token.string"
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {invalid_token}"},
    )
    assert response.status_code == 401


def test_expired_jwt_returns_401():
    # Create an expired token
    expired_token = TokenService.create_access_token(
        data={"sub": "test_user_id", "email": "expired@example.com"},
        expires_delta=timedelta(seconds=-10),
    )

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {expired_token}"},
    )
    assert response.status_code == 401
