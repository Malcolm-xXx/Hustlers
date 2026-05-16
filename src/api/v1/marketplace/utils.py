from __future__ import annotations

import math
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from src.api.v1.auth.schema import (
    AddressResponse,
    CoordinatesResponse,
    LocationResponse,
)
from src.api.v1.marketplace.schema import (
    DispatchSummaryResponse,
    HustleListDetailResponse,
    HustleListItemResponse,
    OrderReferenceResponse,
    SellerSummaryResponse,
    ShoppingPlaceSummary,
)
from src.api.v1.marketplace.schema import (
    HustleListDispatchChannel as DispatchChannelResponse,
)
from src.api.v1.marketplace.schema import (
    HustleListDispatchStatus as DispatchStatusResponse,
)
from src.api.v1.marketplace.schema import (
    HustleListStatus as HustleListStatusResponse,
)
from src.models.auth import Address
from src.models.marketplace import (
    HustleList,
    HustleListDispatch,
    HustleListItem,
)
from src.models.orders import Order, OrderStatus
from src.models.sellers import SellerProfile
from src.api.v1.shared.utils.helpers import parse_uuid
from src.api.v1.shared.utils.encoding import parse_cursor


def parse_list_cursor(cursor: str | None) -> tuple[datetime | None, uuid.UUID | None]:
    """Parse cursor string into timestamp and ID for list pagination."""
    if cursor is None:
        return None, None
    try:
        return parse_cursor(cursor)
    except (ValueError, TypeError):
        return None, None


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points on Earth."""
    radius_km = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    return radius_km * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def coerce_float_or_none(value: object) -> float | None:
    """Coerce value to float, return None if not coercible."""
    if value is None:
        return None
    if isinstance(value, (int, float, Decimal, str)):
        return float(value)
    return None


def page_slice(page: int, page_size: int) -> tuple[int, int]:
    """Calculate pagination slice."""
    start = (page - 1) * page_size
    return start, start + page_size


def dispatch_expiry(default_value: datetime | None = None) -> datetime:
    """Get dispatch expiry time (default 2 hours)."""
    return default_value or (datetime.now(timezone.utc) + timedelta(hours=2))


def serialize_shopping_place(hustle_list: HustleList) -> ShoppingPlaceSummary | None:
    """Serialize shopping location to response schema."""
    shopping_location = hustle_list.shopping_location
    if shopping_location is None:
        return None

    return ShoppingPlaceSummary(
        place_id=shopping_location.provider_place_id,
        name=shopping_location.name,
        formatted_address=shopping_location.address_text,
        latitude=float(shopping_location.latitude),
        longitude=float(shopping_location.longitude),
    )


def serialize_address(address: Address) -> AddressResponse:
    """Serialize address to response schema."""
    return AddressResponse(
        id=address.id,
        location=LocationResponse(
            id=address.id,
            name=address.name,
            address_text=address.address_text,
            coordinates=CoordinatesResponse(
                latitude=float(address.latitude),
                longitude=float(address.longitude),
            ),
        ),
        is_default=address.is_default,
        created_at=address.created_at,
    )


def serialize_seller_summary(seller: SellerProfile) -> SellerSummaryResponse:
    """Serialize seller profile to summary response."""
    return SellerSummaryResponse(id=seller.id, store_name=seller.store_name)


def serialize_item(item: HustleListItem) -> HustleListItemResponse:
    """Serialize hustle list item to response schema."""
    return HustleListItemResponse(
        id=item.id,
        requested_name=item.requested_name,
        quantity_value=str(item.quantity_value),
        unit_label=item.unit_label or None,
        target_price=str(item.target_price) if item.target_price is not None else None,
        note=item.note or None,
    )


def serialize_dispatch(dispatch: HustleListDispatch) -> DispatchSummaryResponse:
    """Serialize dispatch to summary response."""
    target_seller = (
        serialize_seller_summary(dispatch.target_seller)
        if dispatch.target_seller is not None
        else None
    )
    accepted_by_seller = (
        serialize_seller_summary(dispatch.accepted_by_seller)
        if dispatch.accepted_by_seller is not None
        else None
    )
    return DispatchSummaryResponse(
        id=dispatch.id,
        channel=DispatchChannelResponse(dispatch.channel.value),
        status=DispatchStatusResponse(dispatch.status.value),
        target_seller=target_seller,
        accepted_by_seller=accepted_by_seller,
        sent_at=dispatch.sent_at,
        responded_at=dispatch.responded_at,
        expires_at=dispatch.expires_at,
    )


def serialize_order_reference(order: Order) -> OrderReferenceResponse:
    """Serialize order to reference response."""
    return OrderReferenceResponse(
        id=order.id,
        order_number=order.order_number,
        status=order.status.value,
        payment_status=(
            "pending" if order.status == OrderStatus.PENDING_PAYMENT else "paid"
        ),
        created_at=order.created_at,
    )


def subtotal_for_hustle_list(hustle_list: HustleList) -> Decimal:
    """Calculate subtotal for hustle list items."""
    subtotal = Decimal("0.00")
    for item in hustle_list.items:
        if item.target_price is None:
            continue
        subtotal += Decimal(item.target_price) * Decimal(item.quantity_value)
    return subtotal.quantize(Decimal("0.01"))


def serialize_hustle_list(hustle_list: HustleList) -> HustleListDetailResponse:
    """Serialize hustle list to detail response."""
    items = [serialize_item(item) for item in hustle_list.items]
    dispatches = [serialize_dispatch(dispatch) for dispatch in hustle_list.dispatches]

    shopping_place = serialize_shopping_place(hustle_list)
    delivery_address = (
        serialize_address(hustle_list.delivery_address)
        if hustle_list.delivery_address is not None
        else None
    )

    subtotal = subtotal_for_hustle_list(hustle_list)
    delivery_fee = Decimal(hustle_list.delivery_fee).quantize(Decimal("0.01"))

    return HustleListDetailResponse(
        id=hustle_list.id,
        title=hustle_list.title,
        status=HustleListStatusResponse(hustle_list.status.value),
        items_count=len(items),
        subtotal=str(subtotal),
        delivery_fee=str(delivery_fee),
        delivery_window_label=hustle_list.delivery_window_label or None,
        shopping_place=shopping_place,
        created_at=hustle_list.created_at,
        delivery_address=delivery_address,
        notes=hustle_list.notes or None,
        items=items,
        dispatches=dispatches,
    )


def close_other_pending_dispatches(
    hustle_list: HustleList,
    *,
    keep_dispatch_id: uuid.UUID | None = None,
) -> None:
    """Close all other pending dispatches except the one to keep."""
    from src.models.marketplace import HustleListDispatchStatus

    for dispatch in hustle_list.dispatches:
        if dispatch.status != HustleListDispatchStatus.PENDING:
            continue
        if keep_dispatch_id is not None and dispatch.id == keep_dispatch_id:
            continue
        dispatch.status = HustleListDispatchStatus.WITHDRAWN
        dispatch.responded_at = datetime.now(timezone.utc)


__all__ = [
    "haversine_km",
    "coerce_float_or_none",
    "page_slice",
    "dispatch_expiry",
    "serialize_shopping_place",
    "serialize_address",
    "serialize_seller_summary",
    "serialize_item",
    "serialize_dispatch",
    "serialize_order_reference",
    "subtotal_for_hustle_list",
    "serialize_hustle_list",
    "close_other_pending_dispatches",
    "parse_uuid",
]
