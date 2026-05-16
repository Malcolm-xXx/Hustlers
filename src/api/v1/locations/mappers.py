"""Mappers to convert Geoapify API responses to internal Pydantic schemas."""

from src.api.v1.locations.schema import (
    AddressComponent,
    AutocompleteSuggestion,
    PlaceDetailsResponse,
    ReverseGeocodeResult,
)


def map_geoapify_autocomplete_to_suggestions(raw: dict) -> list[AutocompleteSuggestion]:
    """Convert Geoapify autocomplete response to AutocompleteSuggestion list."""
    suggestions = []
    for feature in raw.get("features", []):
        props = feature.get("properties", {})
        suggestions.append(
            AutocompleteSuggestion(
                place_id=props.get("place_id", ""),
                description=props.get("formatted", ""),
                main_text=props.get("address_line1", ""),
                secondary_text=props.get("address_line2", ""),
                types=[props["type"]] if props.get("type") else [],
                distance_meters=props.get("distance"),
            )
        )
    return suggestions


def map_geoapify_place_details_to_response(raw: dict) -> PlaceDetailsResponse:
    """Convert Geoapify place details response to PlaceDetailsResponse."""
    features = raw.get("features", [])
    if not features:
        raise ValueError("No place details found in Geoapify response")
    feature = features[0]
    props = feature.get("properties", {})
    geometry = feature.get("geometry", {})
    coords = geometry.get("coordinates", [0.0, 0.0])  # [lon, lat]

    return PlaceDetailsResponse(
        place_id=props.get("place_id", ""),
        name=props.get("name"),
        display_name=props.get("name"),
        formatted_address=props.get("formatted"),
        lat=coords[1] if len(coords) > 1 else 0.0,
        lng=coords[0] if len(coords) > 0 else 0.0,
        types=props.get("categories", []),
        primary_type=props.get("categories", [""])[0]
        if props.get("categories")
        else None,
    )


def map_geoapify_reverse_geocode_to_results(raw: dict) -> list[ReverseGeocodeResult]:
    """Convert Geoapify reverse geocode response to ReverseGeocodeResult list."""
    results = []
    for feature in raw.get("features", []):
        props = feature.get("properties", {})
        geometry = feature.get("geometry", {})
        coords = geometry.get("coordinates", [0.0, 0.0])

        addr_comps = []
        # Country
        if props.get("country"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["country"],
                    short_name=props.get("country_code", props["country"]),
                    types=["country"],
                )
            )
        # State
        if props.get("state"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["state"],
                    short_name=props.get("state_code", props["state"]),
                    types=["administrative_area_level_1"],
                )
            )
        # City
        if props.get("city"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["city"],
                    short_name=props["city"],
                    types=["locality"],
                )
            )
        # Postcode
        if props.get("postcode"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["postcode"],
                    short_name=props["postcode"],
                    types=["postal_code"],
                )
            )
        # Street
        if props.get("street"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["street"],
                    short_name=props["street"],
                    types=["route"],
                )
            )
        # House number
        if props.get("housenumber"):
            addr_comps.append(
                AddressComponent(
                    long_name=props["housenumber"],
                    short_name=props["housenumber"],
                    types=["street_number"],
                )
            )

        results.append(
            ReverseGeocodeResult(
                formatted_address=props.get("formatted", ""),
                place_id=props.get("place_id"),
                address_components=addr_comps,
                location_type=props.get("type", ""),
                lat=coords[1] if len(coords) > 1 else 0.0,
                lng=coords[0] if len(coords) > 0 else 0.0,
                types=[props["type"]] if props.get("type") else [],
            )
        )
    return results
