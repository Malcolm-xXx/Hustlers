"""Seller-specific serialization helpers."""

import uuid

from starlette.requests import Request

from src.api.v1.shared.schema import LocationSummary, SellerCardResponse
from src.api.v1.sellers.schema import SellerPresenceResponse
from src.models.sellers import SellerProfile, SellerPresenceStatus


def absolute_url(request: Request | None, value: str | None) -> str | None:
    """Convert relative URL to absolute."""
    if not value:
        return None
    if value.startswith("http://") or value.startswith("https://"):
        return value
    if request is None:
        return value
    return f"{str(request.base_url).rstrip('/')}/{value.lstrip('/')}"


def location_summary(location) -> LocationSummary:
    """Create location summary."""
    distance_km = getattr(location, "distance_km", None)
    if distance_km is not None:
        distance_km = round(float(distance_km), 1)
    return LocationSummary(
        id=location.id,
        name=location.name,
        address_text=location.address_text,
        kind="market",
        market_type=None,
        distance_km=distance_km,
        rating=0.0,
        seller_count=0,
    )


def seller_card(
    seller: SellerProfile,
    *,
    request: Request | None,
    favorite_seller_ids: set[uuid.UUID],
) -> SellerCardResponse:
    """Build seller card response."""
    tags = [seller_tag.tag.name for seller_tag in seller.seller_tags if seller_tag.tag]
    presence = getattr(seller, "presence", None)
    status_value = (
        presence.status.value
        if presence is not None
        else SellerPresenceStatus.OFFLINE.value
    )
    distance_km = getattr(seller, "distance_km", None)
    if distance_km is not None:
        distance_km = round(float(distance_km), 1)

    return SellerCardResponse(
        id=seller.id,
        store_name=seller.store_name,
        profile_image=absolute_url(request, seller.profile_image_url),
        status=status_value,
        rating=float(seller.avg_rating),
        rating_count=seller.rating_count,
        completed_orders_count=seller.completed_orders_count,
        distance_km=distance_km,
        tags=tags,
        is_favorite=seller.id in favorite_seller_ids,
    )


def seller_presence_payload(seller: SellerProfile) -> SellerPresenceResponse:
    """Build seller presence response."""
    presence = getattr(seller, "presence", None)
    if presence is None:
        return SellerPresenceResponse(status=SellerPresenceStatus.OFFLINE.value)

    current_location = presence.current_location
    return SellerPresenceResponse(
        status=presence.status.value,
        current_location=(
            location_summary(current_location) if current_location is not None else None
        ),
        last_seen_at=presence.last_seen_at,
    )
