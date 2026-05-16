"""Provider factory to return the configured places client."""

from src.core.config import settings
from src.api.v1.locations.client import GooglePlacesClient
from src.api.v1.locations.geoapify_client import GeoapifyClient


def get_places_client() -> GooglePlacesClient | GeoapifyClient:
    """Return the configured places client based on DEFAULT_PLACES_PROVIDER env var."""
    if settings.DEFAULT_PLACES_PROVIDER == "google_places":
        return GooglePlacesClient()
    return GeoapifyClient()
