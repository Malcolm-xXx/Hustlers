from __future__ import annotations

from typing import TYPE_CHECKING

from fastapi import HTTPException, status

from src.api.v1.locations.schema import (
    AutocompleteRequest,
    PlaceDetailsQuery,
    ReverseGeocodeRequest,
)

if TYPE_CHECKING:
    from src.api.v1.auth.schema import AddressRequest


async def resolve_address_input(
    request: "AddressRequest",
) -> tuple[str, float, float]:
    """Resolve address input - geocode text or reverse geocode coordinates.

    Returns tuple of (address_text, latitude, longitude).
    """
    # Import here to avoid circular dependency
    from src.api.v1.locations.service import (
        autocomplete_service,
        get_place_details_service,
        reverse_geocode_service,
    )

    if request.address_text and request.address_text.strip():
        result = await autocomplete_service(
            AutocompleteRequest(input=request.address_text.strip())
        )
        if not result.suggestions:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Unable to geocode address. Provide valid address text.",
            )
        suggestion = result.suggestions[0]
        details = await get_place_details_service(
            suggestion.place_id,
            query=PlaceDetailsQuery(),
        )
        return (
            details.formatted_address or request.address_text,
            details.lat,
            details.lng,
        )

    if request.latitude is not None and request.longitude is not None:
        result = await reverse_geocode_service(
            ReverseGeocodeRequest(
                lat=request.latitude,
                lng=request.longitude,
            )
        )
        if not result.results:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Unable to reverse geocode coordinates.",
            )
        geocode_result = result.results[0]
        return (
            geocode_result.formatted_address or "",
            geocode_result.lat,
            geocode_result.lng,
        )

    raise HTTPException(
        status.HTTP_400_BAD_REQUEST,
        detail="Provide either address_text or coordinates.",
    )
