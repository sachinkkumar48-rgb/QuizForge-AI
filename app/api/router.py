"""
Root API Router for Project TITAN Backend.
Assembles and exports versioned API routers.
"""
from fastapi import APIRouter

from app.api.v1 import v1_router
from app.core.settings import settings

api_router = APIRouter()

api_router.include_router(v1_router, prefix=settings.API_V1_STR)
