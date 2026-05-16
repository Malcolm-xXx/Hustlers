from pydantic import BaseModel, Field


class AutocompleteRequest(BaseModel):
    input: str = Field(
        ..., min_length=1, max_length=500, description="Text string to search on"
    )
    lat: float | None = Field(
        None, ge=-90, le=90, description="Latitude for location bias"
    )
    lng: float | None = Field(
        None, ge=-180, le=180, description="Longitude for location bias"
    )
    radius: float | None = Field(
        None, gt=0, le=50000, description="Radius in meters for location bias circle"
    )
    language_code: str | None = Field(
        None, max_length=10, description="IETF BCP-47 language code (e.g. 'en', 'es')"
    )
    region_code: str | None = Field(
        None, max_length=5, description="Region code (ccTLD, e.g. 'us', 'gb')"
    )
    types: list[str] | None = Field(
        None, max_length=5, description="Up to 5 primary type filters"
    )
    session_token: str | None = Field(
        None, max_length=200, description="Session token for billing optimization"
    )


class AutocompleteSuggestion(BaseModel):
    place_id: str
    description: str
    main_text: str
    secondary_text: str
    types: list[str]
    distance_meters: int | None = None


class AutocompleteResponse(BaseModel):
    suggestions: list[AutocompleteSuggestion]


class PlaceDetailsQuery(BaseModel):
    language_code: str | None = Field(None, max_length=10)
    region_code: str | None = Field(None, max_length=5)
    session_token: str | None = Field(None, max_length=200)


class AddressComponent(BaseModel):
    long_name: str
    short_name: str
    types: list[str]


class PlaceLocation(BaseModel):
    lat: float
    lng: float


class PlaceGeometry(BaseModel):
    location: PlaceLocation


class PlaceDetailsResponse(BaseModel):
    place_id: str
    name: str | None = None
    display_name: str | None = None
    formatted_address: str | None = None
    lat: float
    lng: float
    types: list[str]
    primary_type: str | None = None


class ReverseGeocodeRequest(BaseModel):
    lat: float = Field(..., ge=-90, le=90, description="Latitude")
    lng: float = Field(..., ge=-180, le=180, description="Longitude")
    language: str | None = Field(
        None, max_length=10, description="Language for results"
    )
    result_type: list[str] | None = Field(
        None, description="Address type filters (e.g. street_address, locality)"
    )
    location_type: list[str] | None = Field(
        None,
        description="Location type filters (e.g. ROOFTOP, RANGE_INTERPOLATED, GEOMETRIC_CENTER, APPROXIMATE)",
    )


class ReverseGeocodeResult(BaseModel):
    formatted_address: str
    place_id: str | None = None
    address_components: list[AddressComponent]
    location_type: str
    lat: float
    lng: float
    types: list[str]


class ReverseGeocodeResponse(BaseModel):
    results: list[ReverseGeocodeResult]
