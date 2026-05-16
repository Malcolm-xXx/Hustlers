from src.api.v1.locations.client import GooglePlacesClient  # noqa: F401
from src.api.v1.locations.geoapify_client import GeoapifyClient
from src.api.v1.locations.mappers import (
    map_geoapify_autocomplete_to_suggestions,
    map_geoapify_place_details_to_response,
    map_geoapify_reverse_geocode_to_results,
)
from src.api.v1.locations.provider import get_places_client
from src.api.v1.locations.schema import (
    AddressComponent,
    AutocompleteRequest,
    AutocompleteResponse,
    AutocompleteSuggestion,
    PlaceDetailsQuery,
    PlaceDetailsResponse,
    ReverseGeocodeRequest,
    ReverseGeocodeResponse,
    ReverseGeocodeResult,
)


async def autocomplete_service(req: AutocompleteRequest) -> AutocompleteResponse:
    """Perform address autocomplete using configured places provider."""
    client = get_places_client()

    if isinstance(client, GeoapifyClient):
        raw = await client.autocomplete(
            input=req.input,
            lat=req.lat,
            lng=req.lng,
            radius=req.radius,
            language_code=req.language_code,
        )
        suggestions = map_geoapify_autocomplete_to_suggestions(raw)
        return AutocompleteResponse(suggestions=suggestions)

    # Google Places fallback
    raw = await client.autocomplete(
        input=req.input,
        lat=req.lat,
        lng=req.lng,
        radius=req.radius,
        language_code=req.language_code,
        region_code=req.region_code,
        types=req.types,
        session_token=req.session_token,
    )

    suggestions: list[AutocompleteSuggestion] = []
    for suggestion in raw.get("suggestions", []):
        place_pred = suggestion.get("placePrediction", {})
        text = place_pred.get("text", {})
        structured = place_pred.get("structuredFormat", {})

        suggestions.append(
            AutocompleteSuggestion(
                place_id=place_pred.get("place", ""),
                description=text.get("text", ""),
                main_text=structured.get("mainText", {}).get("text", ""),
                secondary_text=structured.get("secondaryText", {}).get("text", ""),
                types=place_pred.get("types", []),
                distance_meters=place_pred.get("distanceMeters"),
            )
        )

    return AutocompleteResponse(suggestions=suggestions)


async def get_place_details_service(
    place_id: str,
    query: PlaceDetailsQuery,
) -> PlaceDetailsResponse:
    """Get detailed place information from configured places provider."""
    client = get_places_client()

    if isinstance(client, GeoapifyClient):
        raw = await client.get_place(
            place_id=place_id,
            language_code=query.language_code,
        )
        return map_geoapify_place_details_to_response(raw)

    # Google Places fallback
    raw = await client.get_place(
        place_id=place_id,
        language_code=query.language_code,
        region_code=query.region_code,
        session_token=query.session_token,
    )

    location = raw.get("location", {})
    lat = location.get("latitude", 0.0)
    lng = location.get("longitude", 0.0)
    display_name = raw.get("displayName", {})
    addr = raw.get("formattedAddress", "")

    return PlaceDetailsResponse(
        place_id=raw.get("id", ""),
        name=raw.get("name"),
        display_name=display_name.get("text"),
        formatted_address=addr,
        lat=lat,
        lng=lng,
        types=raw.get("types", []),
        primary_type=raw.get("primaryType"),
    )


async def reverse_geocode_service(
    req: ReverseGeocodeRequest,
) -> ReverseGeocodeResponse:
    """Perform reverse geocoding using configured places provider."""
    client = get_places_client()

    if isinstance(client, GeoapifyClient):
        raw = await client.reverse_geocode(
            lat=req.lat,
            lng=req.lng,
            language=req.language,
            result_type=req.result_type,
        )
        results = map_geoapify_reverse_geocode_to_results(raw)
        return ReverseGeocodeResponse(results=results)

    # Google Places fallback
    raw = await client.reverse_geocode(
        lat=req.lat,
        lng=req.lng,
        language=req.language,
        result_type=req.result_type,
        location_type=req.location_type,
    )

    results: list[ReverseGeocodeResult] = []
    status = raw.get("status", "")

    if status != "OK" and status != "ZERO_RESULTS":
        raise ValueError(f"Geocoding API error: {status}")

    for result in raw.get("results", []):
        geometry = result.get("geometry", {})
        location = geometry.get("location", {})

        address_components: list[AddressComponent] = [
            AddressComponent(
                long_name=c.get("long_name", ""),
                short_name=c.get("short_name", ""),
                types=c.get("types", []),
            )
            for c in result.get("address_components", [])
        ]

        results.append(
            ReverseGeocodeResult(
                formatted_address=result.get("formatted_address", ""),
                place_id=result.get("place_id"),
                address_components=address_components,
                location_type=geometry.get("location_type", ""),
                lat=location.get("lat", req.lat),
                lng=location.get("lng", req.lng),
                types=result.get("types", []),
            )
        )

    return ReverseGeocodeResponse(results=results)
