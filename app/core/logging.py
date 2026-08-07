"""
Structured JSON Logging and Request ID Middleware for TITAN FastAPI Backend.
"""
import json
import logging
import time
import uuid
from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp


SENSITIVE_KEYS = {
    "password",
    "secret",
    "access_token",
    "refresh_token",
    "authorization",
    "api_key",
    "jwt_secret_key",
    "gemini_api_key",
}


def sanitize_value(key: str, value: any) -> any:
    """Sanitizes sensitive values from log extra parameters."""
    if isinstance(key, str) and any(sk in key.lower() for sk in SENSITIVE_KEYS):
        return "***REDACTED***"
    if isinstance(value, dict):
        return {k: sanitize_value(k, v) for k, v in value.items()}
    return value


RESERVED_ATTRS = {
    "args",
    "asctime",
    "created",
    "exc_info",
    "exc_text",
    "filename",
    "funcName",
    "levelname",
    "levelno",
    "lineno",
    "module",
    "msecs",
    "message",
    "msg",
    "name",
    "pathname",
    "process",
    "processName",
    "relativeCreated",
    "stack_info",
    "thread",
    "threadName",
    "taskName",
}


class JSONFormatter(logging.Formatter):
    """Formats log records as structured JSON strings with sensitive data redacting."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }

        # Include all custom contextual attributes, sanitizing sensitive keys
        for key, val in record.__dict__.items():
            if key not in RESERVED_ATTRS and not key.startswith("_"):
                log_data[key] = sanitize_value(key, val)

        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data)



def setup_logging(level: str | int | None = None) -> logging.Logger:
    """Configures structured JSON logging for the application."""
    if level is None:
        try:
            from app.core.settings import settings
            level_str = settings.LOG_LEVEL.upper()
            log_level = getattr(logging, level_str, logging.INFO)
        except Exception:
            log_level = logging.INFO
    elif isinstance(level, str):
        log_level = getattr(logging, level.upper(), logging.INFO)
    else:
        log_level = level

    logger = logging.getLogger("titan_api")
    logger.setLevel(log_level)

    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(JSONFormatter())
        logger.addHandler(handler)

    logger.propagate = False
    return logger


logger = setup_logging()


class RequestIDAndLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to inject Request ID, log request lifecycle, and set X-Request-ID response header."""

    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        start_time = time.time()

        # Extract or generate Request ID
        request_id = request.headers.get("X-Request-ID") or request.headers.get("x-request-id")
        if not request_id:
            request_id = str(uuid.uuid4())

        request.state.request_id = request_id

        try:
            response = await call_next(request)
        except Exception as exc:
            duration_ms = round((time.time() - start_time) * 1000, 2)
            logger.error(
                f"Unhandled exception during request {request.method} {request.url.path}: {exc}",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": 500,
                    "duration_ms": duration_ms,
                    "client_ip": request.client.host if request.client else None,
                },
                exc_info=True,
            )
            raise exc

        duration_ms = round((time.time() - start_time) * 1000, 2)
        response.headers["X-Request-ID"] = request_id

        # Log health and readiness probes at DEBUG level for successful checks to reduce log noise
        is_probe = request.url.path in ("/health", "/ready")
        log_func = logger.debug if (is_probe and response.status_code < 400) else logger.info

        log_func(
            f"HTTP {request.method} {request.url.path} -> {response.status_code} ({duration_ms}ms)",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
                "client_ip": request.client.host if request.client else None,
            },
        )

        return response

