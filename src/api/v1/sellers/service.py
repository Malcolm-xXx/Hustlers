from __future__ import annotations

import uuid
from datetime import UTC, datetime
from decimal import Decimal

from fastapi import status
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from starlette.requests import Request

from src.api.v1.payments.schema import WalletSummaryResponse, WalletWithTodayResponse
from src.api.v1.sellers.queries import (
    get_sellers_by_ids,
    get_users_by_ids,
    load_seller_profile,
)
from src.api.v1.auth.schema import UserSummaryResponse
from src.api.v1.marketplace.schema import ShoppingPlaceSummary
from src.api.v1.sellers.schema import (
    HustleListSummaryResponse,
    LocationSummary,
    OrderSummaryResponse,
    PaginatedHustleListSummaryResponse,
    PaginatedLocationSummaryResponse,
    PaginatedOrderSummaryResponse,
    SellerPresenceResponse,
    SellerPresenceUpdateRequest,
    SellerProfileResponse,
    SellerProfileUpdateRequest,
    SellerServiceAreaCreateRequest,
    ServiceAreaResponse,
)
from src.models.auth import UserRole
from src.models.payments import PaymentStatus
from src.api.v1.sellers.utils import (
    absolute_url,
    location_summary,
    seller_card,
    seller_presence_payload,
)
from src.api.v1.shared.utils.currency import format_money
from src.api.v1.shared.utils.encoding import (
    encode_cursor,
    parse_cursor,
    parse_str_cursor,
)
from src.api.v1.shared.utils.search import build_prefix_tsquery
from src.core.exceptions import HTTPException
from src.models.analytics import LocationDailyMetric
from src.models.auth import User
from src.models.discovery import FavoriteSeller
from src.models.marketplace import (
    HustleList,
    HustleListDispatch,
    HustleListDispatchChannel,
    HustleListDispatchStatus,
    HustleListStatus,
    ServiceAreaLocation,
)
from src.models.orders import Order, OrderStatus
from src.models.payments import (
    Wallet,
    WalletTransaction,
    WalletTransactionStatus,
    WalletTransactionType,
)
from src.models.sellers import (
    SellerPresence,
    SellerProfile,
    SellerServiceArea,
)
from src.models.sellers import SellerPresenceStatus as SellerPresenceModelStatus


def encode_timestamp_cursor(timestamp: datetime, row_id: uuid.UUID) -> str:
    return encode_cursor(timestamp, row_id)


def parse_timestamp_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        return parse_cursor(cursor)
    except (ValueError, TypeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        ) from exc


def encode_text_cursor(value: str, row_id: uuid.UUID) -> str:
    return encode_cursor(value, row_id)


def parse_text_cursor(cursor: str) -> tuple[str, uuid.UUID]:
    try:
        return parse_str_cursor(cursor)
    except (ValueError, TypeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        ) from exc


async def get_favorite_seller_ids(
    db: AsyncSession, user_id: uuid.UUID
) -> set[uuid.UUID]:
    """Get IDs of sellers favorited by a user."""
    result = await db.execute(
        select(FavoriteSeller.seller_id).where(FavoriteSeller.user_id == user_id)
    )
    return set(result.scalars().all())


async def paginate_desc_timestamp(
    db: AsyncSession,
    statement,
    *,
    cursor: str | None,
    limit: int,
    timestamp_column,
    id_column,
):
    """Paginate results by descending timestamp."""
    safe_limit = min(max(limit, 1), 100)
    if cursor is not None:
        cursor_timestamp, cursor_id = parse_timestamp_cursor(cursor)
        statement = statement.where(
            or_(
                timestamp_column < cursor_timestamp,
                and_(timestamp_column == cursor_timestamp, id_column < cursor_id),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    rows = result.scalars().unique().all()
    has_more = len(rows) > safe_limit
    items = rows[:safe_limit]
    next_cursor = None
    if has_more and items:
        tail = items[-1]
        next_cursor = encode_timestamp_cursor(tail.created_at, tail.id)
    return items, next_cursor, has_more


async def paginate_asc_text(
    db: AsyncSession,
    statement,
    *,
    cursor: str | None,
    limit: int,
    text_expression,
    id_column,
):
    """Paginate results by ascending text."""
    safe_limit = min(max(limit, 1), 100)
    if cursor is not None:
        cursor_text, cursor_id = parse_text_cursor(cursor)
        statement = statement.where(
            or_(
                text_expression > cursor_text,
                and_(text_expression == cursor_text, id_column > cursor_id),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    rows = result.scalars().unique().all()
    has_more = len(rows) > safe_limit
    items = rows[:safe_limit]
    next_cursor = None
    if has_more and items:
        tail = items[-1]
        next_cursor = encode_text_cursor(tail.name.lower(), tail.id)
    return items, next_cursor, has_more


def buyer_summary(user: User) -> UserSummaryResponse:
    """Build buyer summary response."""
    return UserSummaryResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_onboarded=user.is_onboarded,
    )


def shopping_place_summary(hustle_list: HustleList) -> ShoppingPlaceSummary | None:
    """Build shopping place summary from hustle list."""
    if hustle_list.shopping_location is None:
        return None
    shopping_location = hustle_list.shopping_location
    return ShoppingPlaceSummary(
        place_id=shopping_location.provider_place_id,
        name=shopping_location.name,
        formatted_address=shopping_location.address_text,
        latitude=shopping_location.latitude,
        longitude=shopping_location.longitude,
    )


def seller_profile_payload(
    seller: SellerProfile,
    *,
    request: Request | None,
    favorite_seller_ids: set[uuid.UUID],
) -> SellerProfileResponse:
    """Build full seller profile response."""
    presence = getattr(seller, "presence", None)
    service_areas = []
    for service_area in seller.service_areas:
        if not service_area.is_active:
            continue
        location = service_area.location
        service_areas.append(
            ServiceAreaResponse(
                id=service_area.id,
                location=location_summary(location) if location is not None else None,
                is_active=service_area.is_active,
                created_at=service_area.created_at,
            ).model_dump(mode="json")
        )

    payload = seller_card(
        seller,
        request=request,
        favorite_seller_ids=favorite_seller_ids,
    ).model_dump(mode="json")
    payload.update(
        {
            "user_id": str(seller.user_id),
            "bio": seller.bio,
            "banner_image": absolute_url(request, seller.banner_image_url),
            "total_items_count": seller.total_items_count,
            "items_on_sale_count": seller.items_on_sale_count,
            "weekly_store_views": seller.weekly_store_views,
            "average_delivery_minutes": seller.average_delivery_minutes,
            "success_rate": float(seller.success_rate),
            "presence": seller_presence_payload(seller).model_dump(mode="json"),
            "service_areas": service_areas,
        }
    )
    if presence is None:
        payload["presence"] = seller_presence_payload(seller).model_dump(mode="json")
    return SellerProfileResponse(**payload)


def hustle_list_summary_payload(hustle_list: HustleList) -> HustleListSummaryResponse:
    """Build hustle list summary response."""
    subtotal = Decimal("0.00")
    for item in hustle_list.items:
        if item.target_price is None:
            continue
        subtotal += item.target_price * item.quantity_value

    return HustleListSummaryResponse(
        id=hustle_list.id,
        title=hustle_list.title,
        status=hustle_list.status,
        items_count=len(hustle_list.items),
        subtotal=format_money(subtotal),
        delivery_fee=format_money(hustle_list.delivery_fee),
        delivery_window_label=hustle_list.delivery_window_label,
        shopping_place=shopping_place_summary(hustle_list),
        created_at=hustle_list.created_at,
    )


def order_summary_payload(
    order: Order,
    *,
    buyer_map: dict[uuid.UUID, User],
    seller_map: dict[uuid.UUID, SellerProfile],
    request: Request | None,
    favorite_seller_ids: set[uuid.UUID],
) -> OrderSummaryResponse:
    """Build order summary response."""
    buyer = buyer_map.get(order.buyer_id)
    seller = seller_map.get(order.seller_id)
    seller_payload = None
    if seller is not None:
        seller_payload = seller_card(
            seller,
            request=request,
            favorite_seller_ids=favorite_seller_ids,
        ).model_dump(mode="json")

    delivery_address_text = ""
    snapshot = order.delivery_address_snapshot_json or {}
    if isinstance(snapshot, dict):
        raw_delivery_address = snapshot.get("address_text")
        if isinstance(raw_delivery_address, str):
            delivery_address_text = raw_delivery_address

    total_amount = (
        order.subtotal_amount + order.delivery_fee_amount + order.service_fee_amount
    )
    return OrderSummaryResponse(
        id=order.id,
        order_number=order.order_number,
        status=order.status,
        payment_status=(
            PaymentStatus.PENDING
            if order.status == OrderStatus.PENDING_PAYMENT
            else PaymentStatus.SUCCEEDED
        ),
        buyer=buyer_summary(buyer)
        if buyer is not None
        else UserSummaryResponse(
            id=order.buyer_id,
            full_name="",
            email="",
            role=UserRole.BUYER,
            is_onboarded=False,
        ),
        seller=seller_payload,
        eta_minutes=order.seller_eta_minutes,
        delivery_address_text=delivery_address_text,
        items_count=len(order.items),
        total_amount=format_money(total_amount),
        created_at=order.created_at,
    )


async def get_seller_wallet_service(
    db: AsyncSession, user: User
) -> WalletWithTodayResponse:
    """Get seller's wallet with today's earnings."""
    result = await db.execute(select(Wallet).where(Wallet.user_id == user.id).limit(1))
    wallet = result.scalar_one_or_none()

    if wallet is None:
        wallet_payload = WalletSummaryResponse()
        amount_in_today = Decimal("0.00")
    else:
        wallet_payload = WalletSummaryResponse(
            wallet_id=wallet.id,
            currency_code=wallet.currency_code,
            available_balance=format_money(wallet.available_balance),
            pending_balance=format_money(wallet.pending_balance),
        )
        today_start = datetime.now(UTC).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        result = await db.execute(
            select(func.coalesce(func.sum(WalletTransaction.amount), 0)).where(
                WalletTransaction.wallet_id == wallet.id,
                WalletTransaction.transaction_type == WalletTransactionType.EARNING,
                WalletTransaction.status == WalletTransactionStatus.SUCCEEDED,
                WalletTransaction.created_at >= today_start,
            )
        )
        amount_in_today = result.scalar_one() or Decimal("0.00")

    return WalletWithTodayResponse(
        wallet=wallet_payload,
        amount_in_today=format_money(amount_in_today),
    )


async def list_seller_active_orders_service(
    db: AsyncSession,
    user: User,
    cursor: str | None,
    limit: int,
    request: Request | None = None,
) -> PaginatedOrderSummaryResponse:
    """List seller's active orders with optimized query."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )
    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)

    statement = (
        select(Order)
        .options(
            selectinload(Order.items),
        )
        .where(
            Order.seller_id == seller.id,
            Order.status.in_(
                [
                    OrderStatus.ACCEPTED,
                    OrderStatus.SHOPPING,
                    OrderStatus.DELIVERING,
                ]
            ),
        )
        .order_by(desc(Order.created_at), desc(Order.id))
    )
    orders, next_cursor, has_more = await paginate_desc_timestamp(
        db,
        statement,
        cursor=cursor,
        limit=limit,
        timestamp_column=Order.created_at,
        id_column=Order.id,
    )

    buyer_ids = {order.buyer_id for order in orders}
    seller_ids = {order.seller_id for order in orders}

    buyer_map = await get_users_by_ids(db, buyer_ids)
    seller_map = await get_sellers_by_ids(db, seller_ids)

    return PaginatedOrderSummaryResponse(
        items=[
            order_summary_payload(
                order,
                buyer_map=buyer_map,
                seller_map=seller_map,
                request=request,
                favorite_seller_ids=favorite_seller_ids,
            )
            for order in orders
        ],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def list_available_lists_service(
    db: AsyncSession,
    user: User,
    cursor: str | None,
    limit: int,
) -> PaginatedHustleListSummaryResponse:
    """List available hustle lists for seller."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )

    statement = (
        select(HustleList)
        .options(
            selectinload(HustleList.items),
        )
        .join(HustleListDispatch, HustleListDispatch.hustle_list_id == HustleList.id)
        .where(
            or_(
                and_(
                    HustleListDispatch.target_seller_id == seller.id,
                    HustleListDispatch.status == HustleListDispatchStatus.PENDING,
                ),
                and_(
                    HustleList.status == HustleListStatus.OPEN,
                    HustleListDispatch.channel == HustleListDispatchChannel.MARKETPLACE,
                    HustleListDispatch.status == HustleListDispatchStatus.PENDING,
                ),
            )
        )
        .distinct()
        .order_by(desc(HustleList.created_at), desc(HustleList.id))
    )
    hustle_lists, next_cursor, has_more = await paginate_desc_timestamp(
        db,
        statement,
        cursor=cursor,
        limit=limit,
        timestamp_column=HustleList.created_at,
        id_column=HustleList.id,
    )

    return PaginatedHustleListSummaryResponse(
        items=[
            hustle_list_summary_payload(hustle_list) for hustle_list in hustle_lists
        ],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def list_high_demand_areas_service(
    db: AsyncSession, user: User
) -> list[LocationSummary]:
    """List high demand areas, optimized to single query."""
    _ = user
    total_orders = func.sum(LocationDailyMetric.orders_count).label("total_orders")
    result = await db.execute(
        select(ServiceAreaLocation)
        .join(
            LocationDailyMetric,
            LocationDailyMetric.location_id == ServiceAreaLocation.id,
        )
        .where(ServiceAreaLocation.is_active.is_(True))
        .group_by(ServiceAreaLocation.id)
        .order_by(desc(total_orders))
        .limit(5)
    )
    locations = result.scalars().all()

    if locations:
        return [location_summary(location) for location in locations]

    result = await db.execute(
        select(ServiceAreaLocation)
        .where(ServiceAreaLocation.is_active.is_(True))
        .order_by(func.lower(ServiceAreaLocation.name), ServiceAreaLocation.id)
        .limit(5)
    )
    return [location_summary(location) for location in result.scalars().all()]


async def get_my_profile_service(
    db: AsyncSession,
    user: User,
    request: Request | None = None,
) -> SellerProfileResponse:
    """Get seller's own profile."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )
    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)
    return seller_profile_payload(
        seller,
        request=request,
        favorite_seller_ids=favorite_seller_ids,
    )


async def update_my_profile_service(
    db: AsyncSession,
    user: User,
    request_data: SellerProfileUpdateRequest,
    request: Request | None = None,
) -> SellerProfileResponse:
    """Update seller's own profile."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )

    if request_data.store_name is not None:
        seller.store_name = request_data.store_name
    if request_data.bio is not None:
        seller.bio = request_data.bio
    if request_data.profile_image is not None:
        seller.profile_image_url = request_data.profile_image
    if request_data.banner_image is not None:
        seller.banner_image_url = request_data.banner_image
    if request_data.is_accepting_orders is not None:
        seller.is_accepting_orders = request_data.is_accepting_orders

    await db.flush()
    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)
    return seller_profile_payload(
        seller,
        request=request,
        favorite_seller_ids=favorite_seller_ids,
    )


async def get_my_presence_service(
    db: AsyncSession, user: User
) -> SellerPresenceResponse:
    """Get seller's presence status."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )
    return seller_presence_payload(seller)


async def update_my_presence_service(
    db: AsyncSession,
    user: User,
    request_data: SellerPresenceUpdateRequest,
) -> SellerPresenceResponse:
    """Update seller's presence status."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )

    result = await db.execute(
        select(SellerPresence).where(SellerPresence.seller_id == seller.id).limit(1)
    )
    presence = result.scalar_one_or_none()
    if presence is None:
        presence = SellerPresence(seller_id=seller.id)
        db.add(presence)

    if request_data.status is not None:
        presence.status = SellerPresenceModelStatus(request_data.status.value)

    if request_data.current_location_id is not None:
        location_result = await db.execute(
            select(ServiceAreaLocation).where(
                ServiceAreaLocation.id == request_data.current_location_id,
                ServiceAreaLocation.is_active.is_(True),
            )
        )
        location = location_result.scalar_one_or_none()
        if location is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"current_location_id": ["Invalid location."]},
            )
        presence.current_location = location

    if (
        request_data.current_location_id is None
        and "current_location_id" in request_data.model_fields_set
    ):
        presence.current_location = None

    presence.last_seen_at = datetime.now(UTC)
    await db.flush()
    return seller_presence_payload(seller)


async def list_service_areas_service(
    db: AsyncSession, user: User
) -> list[ServiceAreaResponse]:
    """List seller's service areas."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )
    result = await db.execute(
        select(SellerServiceArea)
        .options(selectinload(SellerServiceArea.location))
        .where(
            SellerServiceArea.seller_id == seller.id,
            SellerServiceArea.is_active.is_(True),
        )
        .order_by(desc(SellerServiceArea.created_at), desc(SellerServiceArea.id))
    )
    service_areas = result.scalars().all()
    return [
        ServiceAreaResponse(
            id=service_area.id,
            location=(
                location_summary(service_area.location)
                if service_area.location is not None
                else None
            ),
            is_active=service_area.is_active,
            created_at=service_area.created_at,
        )
        for service_area in service_areas
    ]


async def create_service_area_service(
    db: AsyncSession,
    user: User,
    request_data: SellerServiceAreaCreateRequest,
) -> ServiceAreaResponse:
    """Create a new service area for seller."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )

    location_result = await db.execute(
        select(ServiceAreaLocation).where(
            ServiceAreaLocation.id == request_data.location_id,
            ServiceAreaLocation.is_active.is_(True),
        )
    )
    location = location_result.scalar_one_or_none()
    if location is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"location_id": ["Invalid location."]},
        )

    result = await db.execute(
        select(SellerServiceArea)
        .options(selectinload(SellerServiceArea.location))
        .where(
            SellerServiceArea.seller_id == seller.id,
            SellerServiceArea.location_id == location.id,
        )
    )
    service_area = result.scalar_one_or_none()
    if service_area is None:
        service_area = SellerServiceArea(
            seller_id=seller.id,
            location_id=location.id,
            is_active=True,
        )
        db.add(service_area)
    elif not service_area.is_active:
        service_area.is_active = True

    await db.flush()
    service_area.location = location
    return ServiceAreaResponse(
        id=service_area.id,
        location=location_summary(location),
        is_active=service_area.is_active,
        created_at=service_area.created_at,
    )


async def delete_service_area_service(
    db: AsyncSession,
    user: User,
    service_area_id: uuid.UUID,
) -> None:
    """Delete a service area."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )
    result = await db.execute(
        select(SellerServiceArea).where(
            SellerServiceArea.id == service_area_id,
            SellerServiceArea.seller_id == seller.id,
        )
    )
    service_area = result.scalar_one_or_none()
    if service_area is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service area not found.",
        )

    await db.delete(service_area)
    await db.flush()


async def list_service_area_options_service(
    db: AsyncSession,
    user: User,
    cursor: str | None,
    limit: int,
    search: str | None = None,
) -> PaginatedLocationSummaryResponse:
    """List available service area options, optimized single query."""
    seller = await load_seller_profile(
        db,
        user_id=user.id,
        missing_detail="Seller profile is not set up for this account.",
    )

    result = await db.execute(
        select(SellerServiceArea.location_id).where(
            SellerServiceArea.seller_id == seller.id,
            SellerServiceArea.is_active.is_(True),
        )
    )
    active_location_ids = list(result.scalars().all())

    name_expression = func.lower(ServiceAreaLocation.name)
    statement = select(ServiceAreaLocation).where(
        ServiceAreaLocation.is_active.is_(True),
    )
    if active_location_ids:
        statement = statement.where(~ServiceAreaLocation.id.in_(active_location_ids))
    if search:
        search_query = search.strip()
        if search_query:
            tsquery = build_prefix_tsquery(search_query)
            if tsquery is not None:
                search_document = func.to_tsvector(
                    "simple",
                    func.concat_ws(
                        " ",
                        ServiceAreaLocation.name,
                        ServiceAreaLocation.address_text,
                    ),
                )
                statement = statement.where(
                    search_document.op("@@")(func.to_tsquery("simple", tsquery))
                )

    statement = statement.order_by(name_expression, ServiceAreaLocation.id)
    items, next_cursor, has_more = await paginate_asc_text(
        db,
        statement,
        cursor=cursor,
        limit=limit,
        text_expression=name_expression,
        id_column=ServiceAreaLocation.id,
    )
    return PaginatedLocationSummaryResponse(
        items=[location_summary(location) for location in items],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def get_seller_service(
    db: AsyncSession,
    user: User,
    seller_id: uuid.UUID,
    request: Request | None = None,
) -> SellerProfileResponse:
    """Get a seller's profile by seller ID."""
    seller = await load_seller_profile(
        db,
        seller_id=seller_id,
        missing_detail="Seller profile not found.",
    )
    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)
    return seller_profile_payload(
        seller,
        request=request,
        favorite_seller_ids=favorite_seller_ids,
    )
