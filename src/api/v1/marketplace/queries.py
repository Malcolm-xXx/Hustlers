from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Double, cast, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.core.exceptions import HTTPException
from src.models.auth import Address
from src.models.marketplace import (
    HustleList,
    HustleListDispatch,
    HustleListDispatchStatus,
    HustleListItem,
    ServiceAreaLocation,
    ServiceAreaLocationProvider,
)
from src.models.sellers import SellerProfile, SellerPresence, SellerServiceArea


def _hustle_list_loader():
    return [
        selectinload(HustleList.items),
        selectinload(HustleList.dispatches).selectinload(
            HustleListDispatch.target_seller
        ),
        selectinload(HustleList.dispatches).selectinload(
            HustleListDispatch.accepted_by_seller
        ),
        selectinload(HustleList.delivery_address),
        selectinload(HustleList.shopping_location),
    ]


async def get_buyer_list_or_404(
    db: AsyncSession,
    *,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
) -> HustleList:
    """Fetch hustle list owned by buyer with all related data."""
    stmt = (
        select(HustleList)
        .options(*_hustle_list_loader())
        .where(
            HustleList.id == list_id,
            HustleList.buyer_id == user.id,
        )
    )
    result = await db.execute(stmt)
    hustle_list = result.scalar_one_or_none()
    if hustle_list is None:
        raise HTTPException(404, detail="Hustle list not found.")
    return hustle_list


async def get_hustle_list_or_404(
    db: AsyncSession,
    *,
    list_id: uuid.UUID,
) -> HustleList:
    """Fetch any hustle list with all related data."""
    stmt = (
        select(HustleList)
        .options(*_hustle_list_loader())
        .where(HustleList.id == list_id)
    )
    result = await db.execute(stmt)
    hustle_list = result.scalar_one_or_none()
    if hustle_list is None:
        raise HTTPException(404, detail="Hustle list not found.")
    return hustle_list


async def get_seller_profile_for_user(
    db: AsyncSession, user: AuthenticatedActor
) -> SellerProfile:
    """Fetch seller profile for user with all related data."""
    stmt = (
        select(SellerProfile)
        .options(
            selectinload(SellerProfile.presence).selectinload(
                SellerPresence.current_location
            ),
            selectinload(SellerProfile.service_areas).selectinload(
                SellerServiceArea.location
            ),
        )
        .where(SellerProfile.user_id == user.id, SellerProfile.is_deleted.is_(False))
    )
    result = await db.execute(stmt)
    seller_profile = result.scalar_one_or_none()
    if seller_profile is None:
        raise HTTPException(404, detail="Seller profile not found.")
    return seller_profile


async def get_seller_profile_by_id(
    db: AsyncSession,
    seller_id: uuid.UUID,
) -> SellerProfile | None:
    """Fetch seller profile by ID."""
    stmt = select(SellerProfile).where(
        SellerProfile.id == seller_id,
        SellerProfile.is_deleted.is_(False),
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_address_by_id(
    db: AsyncSession,
    address_id: uuid.UUID,
) -> Address | None:
    """Fetch address by ID."""
    stmt = select(Address).where(Address.id == address_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def resolve_shopping_location(
    db: AsyncSession,
    *,
    place_id: str | None,
    name: str | None,
    formatted_address: str | None,
    latitude: float | None,
    longitude: float | None,
) -> ServiceAreaLocation | None:
    """Resolve or create shopping location from input data."""
    if not all(
        value is not None
        for value in (place_id, name, formatted_address, latitude, longitude)
    ):
        return None
    result = await db.execute(
        select(ServiceAreaLocation)
        .where(
            ServiceAreaLocation.provider == ServiceAreaLocationProvider.GOOGLE_PLACES,
            ServiceAreaLocation.provider_place_id == str(place_id),
        )
        .limit(1)
    )
    shopping_location = result.scalar_one_or_none()
    if shopping_location is None:
        shopping_location = ServiceAreaLocation(
            provider=ServiceAreaLocationProvider.GOOGLE_PLACES,
            provider_place_id=str(place_id),
            name=str(name),
            address_text=str(formatted_address),
            latitude=latitude,
            longitude=longitude,
        )
        db.add(shopping_location)
        await db.flush()
    return shopping_location


async def apply_shopping_place_update(
    db: AsyncSession,
    hustle_list: HustleList,
    data: dict[str, object],
) -> None:
    """Update shopping place on hustle list from data dict."""
    from src.api.v1.marketplace.utils import coerce_float_or_none

    field_names = {
        "shopping_place_id",
        "shopping_place_name",
        "shopping_formatted_address",
        "shopping_latitude",
        "shopping_longitude",
    }
    if not (field_names & set(data.keys())):
        return

    shopping_location = await resolve_shopping_location(
        db,
        place_id=(
            str(data.get("shopping_place_id"))
            if data.get("shopping_place_id") is not None
            else None
        ),
        name=(
            str(data.get("shopping_place_name"))
            if data.get("shopping_place_name") is not None
            else None
        ),
        formatted_address=(
            str(data.get("shopping_formatted_address"))
            if data.get("shopping_formatted_address") is not None
            else None
        ),
        latitude=coerce_float_or_none(data.get("shopping_latitude")),
        longitude=coerce_float_or_none(data.get("shopping_longitude")),
    )
    hustle_list.shopping_location = shopping_location


def apply_hustle_list_update(hustle_list: HustleList, data: dict[str, object]) -> None:
    """Apply hustle list field updates from data dict."""
    if "title" in data and data["title"] is not None:
        hustle_list.title = str(data["title"])
    if "delivery_fee" in data and data["delivery_fee"] is not None:
        hustle_list.delivery_fee = Decimal(str(data["delivery_fee"]))
    if "delivery_window_start" in data:
        setattr(hustle_list, "delivery_window_start", data["delivery_window_start"])
    if "delivery_window_end" in data:
        setattr(hustle_list, "delivery_window_end", data["delivery_window_end"])
    if "delivery_window_label" in data:
        hustle_list.delivery_window_label = str(data["delivery_window_label"] or "")
    if "notes" in data:
        hustle_list.notes = str(data["notes"] or "")


async def list_hustle_lists_with_counts(
    db: AsyncSession,
    buyer_id: uuid.UUID,
    *,
    status_filter: str | None = None,
    cursor_created_at: datetime | None = None,
    cursor_id: uuid.UUID | None = None,
    limit: int = 20,
) -> list[HustleList]:
    """List hustle lists for buyer with item counts from DB using cursor pagination."""
    from sqlalchemy import and_

    stmt = (
        select(HustleList)
        .options(
            selectinload(HustleList.items),
            selectinload(HustleList.dispatches).selectinload(
                HustleListDispatch.target_seller
            ),
            selectinload(HustleList.dispatches).selectinload(
                HustleListDispatch.accepted_by_seller
            ),
            selectinload(HustleList.delivery_address),
        )
        .where(HustleList.buyer_id == buyer_id)
        .order_by(HustleList.created_at.desc(), HustleList.id.desc())
    )
    if status_filter is not None:
        stmt = stmt.where(HustleList.status == status_filter)

    if cursor_created_at is not None and cursor_id is not None:
        cursor_condition = or_(
            HustleList.created_at < cursor_created_at,
            and_(
                HustleList.created_at == cursor_created_at,
                HustleList.id < cursor_id,
            ),
        )
        stmt = stmt.where(cursor_condition)

    result = await db.execute(stmt.limit(max(limit, 1)))
    return list(result.scalars().all())


async def get_marketplace_feed_query(
    db: AsyncSession,
    *,
    place_id: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    cursor_created_at: datetime | None = None,
    cursor_id: uuid.UUID | None = None,
    limit: int = 20,
) -> list[HustleList]:
    """Get marketplace feed with SQL-based location filtering."""
    from sqlalchemy import and_, or_
    from src.models.marketplace import HustleListDispatchChannel

    statement = (
        select(HustleList)
        .options(*_hustle_list_loader())
        .join(
            ServiceAreaLocation,
            HustleList.shopping_location_id == ServiceAreaLocation.id,
        )
        .where(
            HustleList.dispatches.any(
                and_(
                    HustleListDispatch.channel == HustleListDispatchChannel.MARKETPLACE,
                    HustleListDispatch.status == HustleListDispatchStatus.PENDING,
                )
            )
        )
        .order_by(HustleList.created_at.desc(), HustleList.id.desc())
    )

    if place_id:
        statement = statement.where(ServiceAreaLocation.provider_place_id == place_id)

    if latitude is not None and longitude is not None:
        radius_meters = 111_320.0
        origin = func.ll_to_earth(latitude, longitude)
        target = func.ll_to_earth(
            cast(ServiceAreaLocation.latitude, Double),
            cast(ServiceAreaLocation.longitude, Double),
        )
        statement = statement.where(
            func.earth_box(origin, radius_meters).op("@>")(target),
            func.earth_distance(origin, target) <= radius_meters,
        )

    if cursor_created_at is not None and cursor_id is not None:
        cursor_condition = or_(
            HustleList.created_at < cursor_created_at,
            and_(
                HustleList.created_at == cursor_created_at,
                HustleList.id < cursor_id,
            ),
        )
        statement = statement.where(cursor_condition)

    result = await db.execute(statement.limit(max(limit, 1)))
    return list(result.scalars().unique().all())


async def calculate_hustle_list_subtotal(
    db: AsyncSession, hustle_list_id: uuid.UUID
) -> Decimal:
    """Calculate subtotal using database aggregation."""
    stmt = select(
        func.coalesce(
            func.sum(HustleListItem.target_price * HustleListItem.quantity_value),
            Decimal("0"),
        )
    ).where(
        HustleListItem.hustle_list_id == hustle_list_id,
        HustleListItem.target_price.isnot(None),
    )
    result = await db.execute(stmt)
    subtotal = result.scalar() or Decimal("0")
    return subtotal.quantize(Decimal("0.01"))


async def refresh_hustle_list(
    db: AsyncSession, hustle_list_id: uuid.UUID
) -> HustleList:
    """Refresh hustle list with all loaded relationships."""
    return await get_hustle_list_or_404(db, list_id=hustle_list_id)


__all__ = [
    "get_buyer_list_or_404",
    "get_hustle_list_or_404",
    "get_seller_profile_for_user",
    "get_seller_profile_by_id",
    "get_address_by_id",
    "resolve_shopping_location",
    "apply_shopping_place_update",
    "apply_hustle_list_update",
    "list_hustle_lists_with_counts",
    "get_marketplace_feed_query",
    "calculate_hustle_list_subtotal",
    "refresh_hustle_list",
]
