"""
Identity repository abstraction and in-memory persistence implementation.
"""
import uuid
from typing import Dict, Optional
from app.identity.models import User


class IdentityRepository:
    """In-memory user repository for authentication."""

    def __init__(self):
        self._users_by_id: Dict[str, User] = {}
        self._users_by_email: Dict[str, User] = {}

    async def get_by_email(self, email: str) -> Optional[User]:
        return self._users_by_email.get(email.strip().lower())

    async def get_by_id(self, user_id: str) -> Optional[User]:
        return self._users_by_id.get(user_id)

    async def create(self, user: User) -> User:
        user_key = user.email.strip().lower()
        self._users_by_id[user.id] = user
        self._users_by_email[user_key] = user
        return user


identity_repository = IdentityRepository()
