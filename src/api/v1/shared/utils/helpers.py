"""General helper utilities."""

import uuid


def parse_uuid(value: str, *, detail: str) -> uuid.UUID:
    """Parse UUID string, raise HTTPException on invalid."""
    try:
        return uuid.UUID(value)
    except ValueError as exc:
        from src.core.exceptions import HTTPException

        raise HTTPException(400, detail=detail) from exc
