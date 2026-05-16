import logging
import sys
from pathlib import Path

import structlog
from structlog.types import Processor

from src.core.config import BASE_DIR, settings

UVICORN_LOGGERS = ("uvicorn", "uvicorn.error", "uvicorn.access")


def get_log_dir() -> Path:
    log_dir = BASE_DIR / "logs"
    log_dir.mkdir(exist_ok=True)
    return log_dir


LOG_DIR = get_log_dir()


SHARED_PROCESSORS: list[Processor] = [
    structlog.contextvars.merge_contextvars,
    structlog.stdlib.add_log_level,
    structlog.stdlib.add_logger_name,
    structlog.processors.TimeStamper(fmt="iso"),
    structlog.processors.format_exc_info,
]


def make_renderer(*, json_logs: bool) -> Processor:
    if json_logs:
        return structlog.processors.JSONRenderer()
    return structlog.dev.ConsoleRenderer(colors=True)


def parse_log_level(log_level: str) -> int:
    level = logging.getLevelName(log_level.upper())
    if not isinstance(level, int):
        raise ValueError(f"Invalid log level: {log_level!r}")
    return level


def silence_uvicorn() -> None:
    for name in UVICORN_LOGGERS:
        logger = logging.getLogger(name)
        logger.handlers.clear()
        logger.propagate = False
        logger.setLevel(logging.CRITICAL)


def init_logging(
    *, json_logs: bool | None = None, log_level: str | None = None
) -> None:
    if json_logs is None:
        json_logs = settings.JSON_LOGS
    if log_level is None:
        log_level = settings.LOG_LEVEL

    level = parse_log_level(log_level)
    renderer = make_renderer(json_logs=json_logs)

    structlog.configure(
        processors=[
            *SHARED_PROCESSORS,
            structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    formatter = structlog.stdlib.ProcessorFormatter(
        foreign_pre_chain=SHARED_PROCESSORS,
        processors=[
            structlog.stdlib.ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
    )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(level)

    silence_uvicorn()


def get_logger(name: str) -> structlog.stdlib.BoundLogger:
    return structlog.get_logger(name)
