import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import sentry_sdk
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sentry_sdk.integrations.logging import LoggingIntegration

from ably import AblyRest
from src.core import ably as ably_module
from src.api.v1.router import router as v1_router
from src.core.config import settings
from src.core.exceptions import AppError
from src.core.logging import get_logger, init_logging
from src.core.middleware import RequestContextMiddleware
from src.utils.images import setup_image_provider

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    init_logging(json_logs=settings.JSON_LOGS, log_level=settings.LOG_LEVEL)
    setup_image_provider()

    if not settings.ABLY_API_KEY:
        msg = "ABLY_API_KEY is not configured"
        raise RuntimeError(msg)
    if not settings.ABLY_SUBSCRIBE_KEY:
        msg = "ABLY_SUBSCRIBE_KEY is not configured"
        raise RuntimeError(msg)
    ably_module._ably_client = AblyRest(settings.ABLY_API_KEY)

    logger.info("application_started", env=settings.ENV, debug=settings.DEBUG)
    yield

    ably_module._ably_client = None
    logger.info("application_shutdown")


sentry_sdk.init(
    dsn=settings.SENTRY_DSN,
    send_default_pii=True,
    enable_logs=True,
    traces_sample_rate=1.0,
    profile_session_sample_rate=1.0,
    profile_lifecycle="trace",
    integrations=[
        LoggingIntegration(
            level=logging.WARNING,  # Capture WARNING and above as breadcrumbs
            event_level=logging.ERROR,  # Send ERROR records as events
            sentry_logs_level=logging.WARNING,  # Capture WARNING and above as Sentry logs
        ),
    ],
)

app = FastAPI(
    lifespan=lifespan,
    docs_url="/api/docs" if settings.ENV == "development" else None,
    redoc_url="/api/redoc" if settings.ENV == "development" else None,
    openapi_url="/api/openapi.json" if settings.ENV == "development" else None,
    title="Hustlers API",
)

app.add_middleware(RequestContextMiddleware)

app.include_router(v1_router, prefix="/api/v1")


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
