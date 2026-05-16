import os
from pathlib import Path
from typing import Literal

from pydantic import ValidationInfo, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent


def _normalize_db_url(url: str) -> str:
    if not url:
        return url

    for prefix in ("postgresql+psycopg2://", "postgres://", "postgresql://"):
        if url.startswith(prefix):
            return "postgresql+asyncpg://" + url[len(prefix) :]

    return url


class BaseAppSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    ENV: Literal["development", "production", "testing"] = "development"
    DEBUG: bool = False

    EMAIL_PROVIDER: Literal["resend", "smtp", "console"] = "console"

    RESEND_API_KEY: str = ""

    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    DEFAULT_FROM_EMAIL: str = ""

    JWT_SECRET_KEY: str = "dev-jwt-secret-change-me"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    EMAIL_VERIFICATION_OTP_EXPIRE_MINUTES: int = 15
    PASSWORD_RESET_OTP_EXPIRE_MINUTES: int = 15

    IMAGE_PROVIDER: Literal["cloudinary", "local"] = "local"

    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    GOOGLE_CLIENT_IDS: list[str] = []

    GOOGLE_MAPS_API_KEY: str = ""
    GEOAPIFY_API_KEY: str = ""
    DEFAULT_PLACES_PROVIDER: Literal["google_places", "geoapify"] = "geoapify"

    PAYSTACK_SECRET_KEY: str = ""
    PAYSTACK_PUBLIC_KEY: str = ""
    PAYSTACK_WEBHOOK_SECRET: str = ""

    SENTRY_DSN: str = ""

    ABLY_API_KEY: str = ""

    ABLY_SUBSCRIBE_KEY: str = ""

    LOG_LEVEL: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    JSON_LOGS: bool = True

    FILE_LOG_MAX_BYTES: int = 10 * 1024 * 1024
    FILE_LOG_BACKUP_COUNT: int = 5

    @field_validator("EMAIL_PROVIDER", mode="after")
    @classmethod
    def validate_email_provider(cls, v: str, info: ValidationInfo) -> str:
        data = info.data
        env = data.get("ENV", "development")
        if v == "resend" and env == "production":
            if not data.get("RESEND_API_KEY"):
                raise ValueError(
                    "RESEND_API_KEY required when EMAIL_PROVIDER is 'resend' in production"
                )
        if v == "smtp" and env == "production":
            if not data.get("SMTP_USER"):
                raise ValueError(
                    "SMTP_USER required when EMAIL_PROVIDER is 'smtp' in production"
                )
            if not data.get("SMTP_PASSWORD"):
                raise ValueError(
                    "SMTP_PASSWORD required when EMAIL_PROVIDER is 'smtp' in production"
                )
        return v

    @field_validator("IMAGE_PROVIDER", mode="after")
    @classmethod
    def validate_image_provider(cls, v: str, info: ValidationInfo) -> str:
        data = info.data
        env = data.get("ENV", "development")
        if v == "cloudinary" and env == "production":
            if not data.get("CLOUDINARY_CLOUD_NAME"):
                raise ValueError(
                    "CLOUDINARY_CLOUD_NAME required when IMAGE_PROVIDER is 'cloudinary' in production"
                )
            if not data.get("CLOUDINARY_API_KEY"):
                raise ValueError(
                    "CLOUDINARY_API_KEY required when IMAGE_PROVIDER is 'cloudinary' in production"
                )
            if not data.get("CLOUDINARY_API_SECRET"):
                raise ValueError(
                    "CLOUDINARY_API_SECRET required when IMAGE_PROVIDER is 'cloudinary' in production"
                )
        return v


class DevSettings(BaseAppSettings):
    DEBUG: bool = True
    JSON_LOGS: bool = False
    ENV: Literal["development", "production", "testing"] = "development"

    POSTGRES_DB: str = "hustlers_db"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        db_url = os.getenv("DATABASE_URL", "")
        if db_url:
            return _normalize_db_url(db_url)
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )


class ProdSettings(BaseAppSettings):
    DATABASE_URL: str

    @field_validator("DATABASE_URL")
    @classmethod
    def validate_db_url(cls, v: str) -> str:
        return _normalize_db_url(v)


def get_settings() -> DevSettings | ProdSettings:
    env = os.getenv("ENV", "development")
    match env:
        case "production":
            return ProdSettings()  # ty:ignore[missing-argument]
        case _:
            return DevSettings()


settings = get_settings()
