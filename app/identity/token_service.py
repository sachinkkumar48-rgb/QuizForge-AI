"""
JWT Token Service for generating and verifying Access and Refresh tokens.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
import jwt

from app.core.settings import settings
from app.identity.exceptions import InvalidTokenException


class TokenService:
    """Service class for handling JWT tokens."""

    @staticmethod
    def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        now = datetime.now(timezone.utc)
        if expires_delta:
            expire = now + expires_delta
        else:
            expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire, "type": "access"})
        return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    @staticmethod
    def verify_access_token(token: str) -> Dict[str, Any]:
        try:
            payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
            if payload.get("type") != "access":
                raise InvalidTokenException("Invalid token type. Expected access token.")
            return payload
        except jwt.ExpiredSignatureError:
            raise InvalidTokenException("Access token has expired.")
        except jwt.PyJWTError as e:
            raise InvalidTokenException(f"Invalid access token: {e}")

    @staticmethod
    def create_refresh_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        now = datetime.now(timezone.utc)
        if expires_delta:
            expire = now + expires_delta
        else:
            expire = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    @staticmethod
    def verify_refresh_token(token: str) -> Dict[str, Any]:
        try:
            payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
            if payload.get("type") != "refresh":
                raise InvalidTokenException("Invalid token type. Expected refresh token.")
            return payload
        except jwt.ExpiredSignatureError:
            raise InvalidTokenException("Refresh token has expired.")
        except jwt.PyJWTError as e:
            raise InvalidTokenException(f"Invalid refresh token: {e}")


create_access_token = TokenService.create_access_token
verify_access_token = TokenService.verify_access_token
create_refresh_token = TokenService.create_refresh_token
verify_refresh_token = TokenService.verify_refresh_token

