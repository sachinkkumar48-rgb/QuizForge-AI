"""
FastAPI Main Application Entry Point with Observability, Settings, and Identity/Auth Module.
"""
import uuid
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.quiz import router as quiz_router
from app.core.logging import RequestIDAndLoggingMiddleware, logger
from app.core.settings import settings
from app.identity.exceptions import IdentityException
from app.identity.router import router as auth_router
from app.services.gemini_service import GeminiServiceException

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.5.0",
    description="Backend API service for Project TITAN",
)

# CORS Middleware
if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Attach Request ID and Structured JSON Logging Middleware
app.add_middleware(RequestIDAndLoggingMiddleware)


@app.get("/health")
def health_check():
    """Health check endpoint for liveness probe."""
    return {"status": "healthy", "project": settings.PROJECT_NAME, "env": settings.APP_ENV, "version": "1.5.0"}


@app.get("/ready")
def ready_check():
    """Readiness check endpoint for traffic readiness probe."""
    return {"status": "ready", "project": settings.PROJECT_NAME, "env": settings.APP_ENV, "version": "1.5.0"}


@app.get("/")
def read_root():
    """Root status endpoint."""
    return {"status": "online", "project": settings.PROJECT_NAME, "env": settings.APP_ENV, "version": "1.5.0"}


@app.exception_handler(IdentityException)
async def identity_exception_handler(request: Request, exc: IdentityException):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.__class__.__name__,
            "message": exc.message,
            "request_id": request_id,
        },
        headers={"X-Request-ID": request_id},
    )


@app.exception_handler(GeminiServiceException)
async def gemini_exception_handler(request: Request, exc: GeminiServiceException):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.__class__.__name__,
            "message": exc.message,
            "request_id": request_id,
        },
        headers={"X-Request-ID": request_id},
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.error(
        f"Global unhandled error: {exc}",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": 500,
        },
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "InternalServerError",
            "message": "An unexpected error occurred on the server.",
            "request_id": request_id,
        },
        headers={"X-Request-ID": request_id},
    )


app.include_router(quiz_router, prefix=settings.API_V1_STR + "/quiz")
app.include_router(auth_router, prefix=settings.API_V1_STR + "/auth")
