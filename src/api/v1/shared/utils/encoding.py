"""Cursor encoding/decoding utilities."""

import uuid
from datetime import datetime, timezone


def encode_cursor(value: datetime | str, row_id: uuid.UUID) -> str:
    """Encode a (value, UUID) pair as a cursor string."""
    if isinstance(value, datetime):
        value = value.astimezone(timezone.utc).isoformat()
    return f"{value}|{row_id}"


def parse_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    """Decode a cursor string to (datetime, UUID)."""
    value_raw, row_id_raw = cursor.split("|", 1)
    parsed = datetime.fromisoformat(value_raw)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed, uuid.UUID(row_id_raw)


def parse_str_cursor(cursor: str) -> tuple[str, uuid.UUID]:
    """Decode a cursor string to (str, UUID)."""
    value_raw, row_id_raw = cursor.split("|", 1)
    return value_raw, uuid.UUID(row_id_raw)
