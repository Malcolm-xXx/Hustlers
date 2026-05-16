"""URL manipulation utilities."""

from starlette.requests import Request


def absolute_url(request: Request | None, value: str | None) -> str | None:
    """Convert relative URL to absolute."""
    if not value:
        return None
    if value.startswith("http://") or value.startswith("https://"):
        return value
    if request is None:
        return value
    return str(request.base_url).rstrip("/") + "/" + value.lstrip("/")
