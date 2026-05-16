from fastapi import APIRouter, Query

from src.api.v1.locations.schema import (
    AutocompleteRequest,
    AutocompleteResponse,
    PlaceDetailsQuery,
    PlaceDetailsResponse,
    ReverseGeocodeRequest,
    ReverseGeocodeResponse,
)
from src.api.v1.locations.service import (
    autocomplete_service,
    get_place_details_service,
    reverse_geocode_service,
)
from src.core.exceptions import AppError, HTTPException

router = APIRouter()


@router.post("/autocomplete", response_model=AutocompleteResponse, tags=["locations"])
async def autocomplete(req: AutocompleteRequest) -> AutocompleteResponse:
    return await autocomplete_service(req)


@router.get(
    "/places/{place_id}",
    response_model=PlaceDetailsResponse,
    tags=["locations"],
)
async def get_place(
    place_id: str,
    language_code: str | None = Query(None, max_length=10),
    region_code: str | None = Query(None, max_length=5),
    session_token: str | None = Query(None, max_length=200),
) -> PlaceDetailsResponse:
    try:
        return await get_place_details_service(
            place_id=place_id,
            query=PlaceDetailsQuery(
                language_code=language_code,
                region_code=region_code,
                session_token=session_token,
            ),
        )
    except AppError:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e)) from e


@router.post(
    "/reverse-geocode",
    response_model=ReverseGeocodeResponse,
    tags=["locations"],
)
async def reverse_geocode(req: ReverseGeocodeRequest) -> ReverseGeocodeResponse:
    try:
        return await reverse_geocode_service(req)
    except AppError:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e)) from e
