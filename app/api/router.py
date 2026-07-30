"""
Root API Router for Project TITAN Backend.
Assembles and exports all application API routers.
"""
from fastapi import APIRouter

from app.api.v1.quiz import router as quiz_router
from app.core.settings import settings
from app.identity.router import router as auth_router

api_router = APIRouter()

api_router.include_router(quiz_router, prefix=settings.API_V1_STR + "/quiz")
api_router.include_router(auth_router, prefix=settings.API_V1_STR + "/auth")
