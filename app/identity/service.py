"""
Identity service business logic implementation for authentication.
"""
import uuid
from typing import Dict, Any

from app.identity.exceptions import InvalidCredentialsException, InvalidTokenException, UserAlreadyExistsException
from app.identity.models import User
from app.identity.repository import IdentityRepository, identity_repository
from app.identity.schemas import TokenResponse, UserLoginRequest, UserRegisterRequest, UserResponse
from app.identity.security import SecurityService
from app.identity.token_service import TokenService


class AuthService:
    """Service providing authentication and user identity management."""

    def __init__(self, repository: IdentityRepository = identity_repository):
        self.repository = repository
        self.security = SecurityService()
        self.token_service = TokenService()

    async def register(self, request: UserRegisterRequest) -> TokenResponse:
        existing_user = await self.repository.get_by_email(request.email)
        if existing_user:
            raise UserAlreadyExistsException("User with this email already exists.")

        user_id = str(uuid.uuid4())
        hashed_password = self.security.hash_password(request.password)

        new_user = User(
            id=user_id,
            email=request.email.strip().lower(),
            hashed_password=hashed_password,
            full_name=request.full_name,
        )

        await self.repository.create(new_user)

        token_payload = {"sub": new_user.id, "email": new_user.email}
        access_token = self.token_service.create_access_token(token_payload)
        refresh_token = self.token_service.create_refresh_token(token_payload)

        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            refresh_token=refresh_token,
        )

    async def login(self, request: UserLoginRequest) -> TokenResponse:
        user = await self.repository.get_by_email(request.email)
        if not user:
            raise InvalidCredentialsException("Invalid email or password.")

        if not self.security.verify_password(request.password, user.hashed_password):
            raise InvalidCredentialsException("Invalid email or password.")

        token_payload = {"sub": user.id, "email": user.email}
        access_token = self.token_service.create_access_token(token_payload)
        refresh_token = self.token_service.create_refresh_token(token_payload)

        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            refresh_token=refresh_token,
        )

    async def refresh(self, refresh_token: str) -> TokenResponse:
        payload = self.token_service.verify_refresh_token(refresh_token)
        user_id = payload.get("sub")
        if not user_id:
            raise InvalidTokenException("Invalid refresh token payload.")

        user = await self.repository.get_by_id(user_id)
        if not user or not user.is_active:
            raise InvalidTokenException("User not found or inactive.")

        token_payload = {"sub": user.id, "email": user.email}
        new_access_token = self.token_service.create_access_token(token_payload)
        new_refresh_token = self.token_service.create_refresh_token(token_payload)

        return TokenResponse(
            access_token=new_access_token,
            token_type="bearer",
            refresh_token=new_refresh_token,
        )

    async def logout(self, token: str) -> bool:
        # Token revocation can be tracked if needed
        return True

    async def get_current_user(self, token: str) -> UserResponse:
        payload = self.token_service.verify_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise InvalidTokenException("Invalid access token payload.")

        user = await self.repository.get_by_id(user_id)
        if not user:
            raise InvalidTokenException("User specified in token does not exist.")

        return UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            is_active=user.is_active,
        )


auth_service = AuthService()
