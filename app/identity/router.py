"""
FastAPI APIRouter for Identity and Authentication endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.identity.dependencies import get_current_user
from app.identity.exceptions import IdentityException
from app.identity.schemas import TokenResponse, UserLoginRequest, UserRegisterRequest, UserResponse
from app.identity.service import auth_service

router = APIRouter(tags=["auth"])


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(description="JWT refresh token.")


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(request: UserRegisterRequest):
    """Register a new user account and return JWT tokens."""
    try:
        return await auth_service.register(request)
    except IdentityException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/login", response_model=TokenResponse)
async def login(request: UserLoginRequest):
    """Authenticate user credentials and issue access and refresh JWT tokens."""
    try:
        return await auth_service.login(request)
    except IdentityException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(request: RefreshTokenRequest):
    """Refresh access token using a valid refresh token."""
    try:
        return await auth_service.refresh(request.refresh_token)
    except IdentityException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/logout")
async def logout():
    """Log out current user."""
    return {"success": True, "message": "Successfully logged out."}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: UserResponse = Depends(get_current_user)):
    """Retrieve authenticated user details."""
    return current_user
