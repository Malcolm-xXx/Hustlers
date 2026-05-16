"""Google Places API client singleton."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from google.api_core.client_options import ClientOptions
from google.maps.places_v1.types import places_service
from google.type.latlng_pb2 import LatLng

from src.core.config import settings

if TYPE_CHECKING:
    import httpx
    from google.maps.places_v1 import PlacesAsyncClient


AUTOCOMPLETE_FIELDS = (
    "suggestions.placePrediction.place,"
    "suggestions.placePrediction.text.text,"
    "suggestions.placePrediction.structuredFormat.mainText.text,"
    "suggestions.placePrediction.structuredFormat.secondaryText.text,"
    "suggestions.placePrediction.types,"
    "suggestions.placePrediction.distanceMeters"
)

PLACE_DETAILS_MASK = "id,displayName,formattedAddress,location,types,primaryType"

GEOCODING_BASE = "https://maps.googleapis.com/maps/api/geocode/json"


class GooglePlacesClient:
    _instance: GooglePlacesClient | None = None

    def __new__(cls) -> GooglePlacesClient:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._places: PlacesAsyncClient | None = None  # type: ignore[valid-type]
            cls._instance._http: httpx.AsyncClient | None = None  # type: ignore[valid-type]
        return cls._instance

    @property
    def places(self) -> PlacesAsyncClient:
        if self._places is None:
            from google.maps.places_v1 import PlacesAsyncClient

            self._places = PlacesAsyncClient(
                client_options=ClientOptions(api_key=settings.GOOGLE_MAPS_API_KEY),
            )
        return self._places

    @property
    def http(self) -> httpx.AsyncClient:
        if self._http is None:
            import httpx

            self._http = httpx.AsyncClient(timeout=10.0)
        return self._http

    async def close(self) -> None:
        if self._http is not None:
            await self._http.aclose()
            self._http = None

    async def autocomplete(
        self,
        input: str,
        lat: float | None = None,
        lng: float | None = None,
        radius: float | None = None,
        language_code: str | None = None,
        region_code: str | None = None,
        types: list[str] | None = None,
        session_token: str | None = None,
    ) -> dict[str, Any]:
        request: dict[str, Any] = {"input": input}
        if lat is not None and lng is not None:
            center = LatLng(latitude=lat, longitude=lng)
            if radius is not None:
                request["location_bias"] = {
                    "circle": {"center": center, "radius": radius}
                }
            else:
                request["location_bias"] = {
                    "circle": {"center": center, "radius": 5000.0}
                }
        if language_code:
            request["language_code"] = language_code
        if region_code:
            request["region_code"] = region_code
        if types:
            request["included_primary_types"] = types[:5]
        if session_token:
            request["session_token"] = session_token

        metadata = (("X-Goog-FieldMask", AUTOCOMPLETE_FIELDS),)
        response = await self.places.autocomplete_places(
            places_service.AutocompletePlacesRequest(request),
            metadata=metadata,
        )
        return type(response).to_dict(response)

    async def get_place(
        self,
        place_id: str,
        language_code: str | None = None,
        region_code: str | None = None,
        session_token: str | None = None,
    ) -> dict[str, Any]:
        request = places_service.GetPlaceRequest(
            name=f"places/{place_id}",
            language_code=language_code,
            region_code=region_code,
            session_token=session_token,
        )
        metadata = (("X-Goog-FieldMask", PLACE_DETAILS_MASK),)
        response = await self.places.get_place(request=request, metadata=metadata)
        return type(response).to_dict(response)

    async def reverse_geocode(
        self,
        lat: float,
        lng: float,
        language: str | None = None,
        result_type: list[str] | None = None,
        location_type: list[str] | None = None,
    ) -> dict[str, Any]:
        params: dict[str, str | float] = {
            "latlng": f"{lat},{lng}",
            "key": settings.GOOGLE_MAPS_API_KEY,
        }
        if language:
            params["language"] = language
        if result_type:
            params["result_type"] = "|".join(result_type)
        if location_type:
            params["location_type"] = "|".join(location_type)

        response = await self.http.get(GEOCODING_BASE, params=params)
        response.raise_for_status()
        return response.json()
