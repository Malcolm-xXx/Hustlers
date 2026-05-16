"""Notification-specific helper utilities."""

import uuid


def parse_uuid_or_none(value: str) -> uuid.UUID | None:
    """Parse UUID string, return None if invalid."""
    if not isinstance(value, str):
        return None
    try:
        return uuid.UUID(value)
    except ValueError:
        return None
