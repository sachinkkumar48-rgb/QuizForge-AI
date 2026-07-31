"""
Core Settings and Environment Configurations for TITAN FastAPI Backend.
"""
import os
from typing import List
from dotenv import load_dotenv
from pydantic import BaseModel, Field, model_validator

load_dotenv()


class Settings(BaseModel):
    PROJECT_NAME: str = Field(default="TITAN API")
    API_V1_STR: str = Field(default="/api/v1")
    GEMINI_API_KEY: str = Field(default_factory=lambda: os.getenv("GEMINI_API_KEY", ""))
    GEMINI_MODEL: str = Field(default_factory=lambda: os.getenv("GEMINI_MODEL", "gemini-2.5-flash"))
    APP_ENV: str = Field(default_factory=lambda: os.getenv("APP_ENV", "development"))
    LOG_LEVEL: str = Field(default_factory=lambda: os.getenv("LOG_LEVEL", "INFO"))
    HOST: str = Field(default_factory=lambda: os.getenv("HOST", "0.0.0.0"))
    PORT: int = Field(default_factory=lambda: int(os.getenv("PORT", "8000")))
    CORS_ORIGINS: List[str] = Field(
        default_factory=lambda: [
            origin.strip()
            for origin in os.getenv("CORS_ORIGINS", "*").split(",")
            if origin.strip()
        ]
    )

    # JWT Settings
    JWT_SECRET_KEY: str = Field(
        default_factory=lambda: os.getenv("JWT_SECRET_KEY", "titan-super-secret-jwt-key-change-in-production")
    )
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        default_factory=lambda: int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    )
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(
        default_factory=lambda: int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    )

    @model_validator(mode="after")
    def validate_production_config(self) -> "Settings":
        """
        Validates critical configuration parameters when running in production environment.
        """
        if self.APP_ENV.lower() == "production":
            if self.JWT_SECRET_KEY == "titan-super-secret-jwt-key-change-in-production":
                raise ValueError("JWT_SECRET_KEY must be explicitly configured in production environment.")
            if not self.GEMINI_API_KEY or self.GEMINI_API_KEY.strip() == "" or self.GEMINI_API_KEY == "your_gemini_api_key_here":
                raise ValueError("GEMINI_API_KEY is required in production environment.")
            if "*" in self.CORS_ORIGINS:
                raise ValueError("Wildcard CORS_ORIGINS ('*') is not allowed in production environment.")
        return self


settings = Settings()
