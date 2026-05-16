from typing import AsyncGenerator
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from src.core.config import settings


class Base(DeclarativeBase):
    pass


# Lazy engine initialization
_engine: AsyncEngine | None = None


def get_engine():
    global _engine
    if _engine is None:
        parsed = urlparse(settings.DATABASE_URL)
        params = parse_qs(parsed.query, keep_blank_values=True)

        params.pop("ssl", None)
        params.pop("sslmode", None)
        params.pop("channel_binding", None)

        connect_args = {"ssl": "require"} if settings.ENV == "production" else {}

        clean_url = urlunparse(
            parsed._replace(query=urlencode({k: v[0] for k, v in params.items()}))
        )

        _engine = create_async_engine(
            clean_url,
            echo=settings.DEBUG,
            pool_size=10,
            max_overflow=20,
            connect_args=connect_args,
        )
    return _engine


# Lazy session maker initialization
_async_session_local: async_sessionmaker[AsyncSession] | None = None


def get_session_local() -> async_sessionmaker[AsyncSession]:
    global _async_session_local
    if _async_session_local is None:
        _async_session_local = async_sessionmaker(
            bind=get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
        )
    return _async_session_local


# Dependency for FastAPI routes
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with get_session_local()() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
