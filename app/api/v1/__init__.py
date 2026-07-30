"""
API v1 Router Initialization.
Aggregates all API v1 feature routes under the /api/v1 namespace.
"""
from fastapi import APIRouter

from app.api.v1.quiz import router as quiz_router
from app.identity.router import router as auth_router

v1_router = APIRouter()

v1_router.include_router(quiz_router, prefix="/quiz")
v1_router.include_router(auth_router, prefix="/auth")
