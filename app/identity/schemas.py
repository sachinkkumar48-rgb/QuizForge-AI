"""
Pydantic schemas for Identity and Authentication.
"""
from typing import Optional
from pydantic import BaseModel, Field


class UserRegisterRequest(BaseModel):
    email: str = Field(description="User email address.")
    password: str = Field(min_length=8, description="User password.")
    full_name: Optional[str] = Field(default=None, description="Optional user full name.")


class UserLoginRequest(BaseModel):
    email: str = Field(description="User email address.")
    password: str = Field(description="User password.")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str] = None
    is_active: bool = True
