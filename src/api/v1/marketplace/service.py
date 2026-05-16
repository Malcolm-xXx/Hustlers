from __future__ import annotations

import uuid
from datetime import datetime, timezone
from decimal import ROUND_HALF_UP, Decimal

from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.models.sellers import SellerProfile

from src.api.v1.marketplace.queries import (
    apply_hustle_list_update,
    apply_shopping_place_update,
    calculate_hustle_list_subtotal,
    get_address_by_id,
    get_buyer_list_or_404,
    get_marketplace_feed_query,
    get_seller_profile_by_id,
    get_seller_profile_for_user,
    list_hustle_lists_with_counts,
    refresh_hustle_list,
    resolve_shopping_location,
)
from src.api.v1.marketplace.schema import (
    DispatchAction,
    DispatchDecisionRequest,
    DispatchDecisionResponse,
    DispatchDetailResponse,
    DispatchSummaryResponse,
    HustleListDetailResponse,
    HustleListItemCreateRequest,
    HustleListItemUpdateRequest,
    HustleListPublishRequest,
    HustleListRequest,
    HustleListSendRequest,
    HustleListSummaryResponse,
    HustleListUpdateRequest,
    HustleListWithdrawRequest,
    PublishResponse,
    SendResponse,
)
from src.api.v1.marketplace.utils import (
    close_other_pending_dispatches,
    dispatch_expiry,
    serialize_dispatch,
    serialize_hustle_list,
    serialize_order_reference,
)
from src.core.exceptions import HTTPException
from src.models.marketplace import (
    HustleList,
    HustleListDispatch,
    HustleListDispatchChannel,
    HustleListDispatchStatus,
    HustleListItem,
    HustleListStatus,
)
from src.models.orders import Order, OrderSourceType, OrderStatus


async def create_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: HustleListRequest,
) -> HustleListDetailResponse:
    """Create a new hustle list."""
    if (request.delivery_window_start is not None) != (
        request.delivery_window_end is not None
    ):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="delivery_window_start and delivery_window_end must be provided together.",
        )
    if (
        request.delivery_window_start is not None
        and request.delivery_window_end is not None
        and request.delivery_window_end <= request.delivery_window_start
    ):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="delivery_window_end must be after delivery_window_start.",
        )

    delivery_address = None
    if request.delivery_address_id is not None:
        delivery_address = await get_address_by_id(db, request.delivery_address_id)
        if delivery_address is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Delivery address not found."
            )

    shopping_location = await resolve_shopping_location(
        db,
        place_id=request.shopping_place_id,
        name=request.shopping_place_name,
        formatted_address=request.shopping_formatted_address,
        latitude=request.shopping_latitude,
        longitude=request.shopping_longitude,
    )

    hustle_list = HustleList(
        buyer_id=user.id,
        title=request.title,
        shopping_location=shopping_location,
        delivery_address=delivery_address,
        delivery_fee=request.delivery_fee,
        delivery_window_start=request.delivery_window_start,
        delivery_window_end=request.delivery_window_end,
        delivery_window_label=request.delivery_window_label or "",
        notes=request.notes or "",
    )
    db.add(hustle_list)
    await db.flush()

    for sort_order, item in enumerate(request.items):
        hustle_list.items.append(
            HustleListItem(
                requested_name=item.requested_name,
                quantity_value=item.quantity_value,
                unit_label=item.unit_label or "",
                target_price=item.target_price,
                note=item.note or "",
                sort_order=sort_order,
            )
        )

    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def list_hustle_lists_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    status_filter: str | None = None,
    cursor: str | None = None,
    limit: int = 20,
) -> list[HustleListSummaryResponse]:
    """List all hustle lists for the buyer."""
    from src.api.v1.marketplace.utils import parse_list_cursor

    cursor_created_at, cursor_id = parse_list_cursor(cursor)
    lists = await list_hustle_lists_with_counts(
        db,
        user.id,
        status_filter=status_filter,
        cursor_created_at=cursor_created_at,
        cursor_id=cursor_id,
        limit=limit,
    )
    return [
        HustleListSummaryResponse.model_validate(serialize_hustle_list(h).model_dump())
        for h in lists
    ]


async def get_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
) -> HustleListDetailResponse:
    """Get a specific hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    return serialize_hustle_list(hustle_list)


async def update_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    request: HustleListUpdateRequest,
) -> HustleListDetailResponse:
    """Update an existing hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    data = request.model_dump(exclude_unset=True)

    await apply_shopping_place_update(db, hustle_list, data)

    if "delivery_address_id" in data:
        delivery_address_id = data.get("delivery_address_id")
        if delivery_address_id is None:
            setattr(hustle_list, "delivery_address", None)
        else:
            delivery_address = await get_address_by_id(
                db, uuid.UUID(str(delivery_address_id))
            )
            if delivery_address is None:
                raise HTTPException(
                    status.HTTP_404_NOT_FOUND, detail="Delivery address not found."
                )
            hustle_list.delivery_address = delivery_address

    apply_hustle_list_update(hustle_list, data)

    if hustle_list.delivery_window_start and hustle_list.delivery_window_end:
        if hustle_list.delivery_window_end <= hustle_list.delivery_window_start:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="delivery_window_end must be after delivery_window_start.",
            )

    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def delete_hustle_list_service(
    db: AsyncSession, user: AuthenticatedActor, list_id: uuid.UUID
) -> None:
    """Delete a hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    await db.delete(hustle_list)


async def create_hustle_list_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    request: HustleListItemCreateRequest,
) -> HustleListDetailResponse:
    """Add an item to a hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    next_sort = max((item.sort_order for item in hustle_list.items), default=-1) + 1
    hustle_list.items.append(
        HustleListItem(
            requested_name=request.requested_name,
            quantity_value=request.quantity_value,
            unit_label=request.unit_label or "",
            target_price=request.target_price,
            note=request.note or "",
            sort_order=next_sort,
        )
    )
    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def update_hustle_list_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    item_id: uuid.UUID,
    request: HustleListItemUpdateRequest,
) -> HustleListDetailResponse:
    """Update an item in a hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    item = next((row for row in hustle_list.items if row.id == item_id), None)
    if item is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Hustle list item not found."
        )

    data = request.model_dump(exclude_unset=True)
    if "requested_name" in data and data["requested_name"] is not None:
        item.requested_name = str(data["requested_name"])
    if "quantity_value" in data and data["quantity_value"] is not None:
        item.quantity_value = Decimal(str(data["quantity_value"]))
    if "unit_label" in data:
        item.unit_label = str(data["unit_label"] or "")
    if "target_price" in data:
        value = data["target_price"]
        item.target_price = None if value is None else Decimal(str(value))
    if "note" in data:
        item.note = str(data["note"] or "")

    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def delete_hustle_list_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    item_id: uuid.UUID,
) -> HustleListDetailResponse:
    """Delete an item from a hustle list."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    item = next((row for row in hustle_list.items if row.id == item_id), None)
    if item is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Hustle list item not found."
        )

    await db.delete(item)
    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def send_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    request: HustleListSendRequest,
) -> SendResponse:
    """Send a hustle list to a specific seller."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    target_seller = await get_seller_profile_by_id(db, request.seller_id)
    if target_seller is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Seller not found.")

    dispatch = HustleListDispatch(
        hustle_list_id=hustle_list.id,
        channel=HustleListDispatchChannel.DIRECT,
        target_seller=target_seller,
        status=HustleListDispatchStatus.PENDING,
        sent_at=datetime.now(timezone.utc),
        expires_at=dispatch_expiry(request.expires_at),
    )
    db.add(dispatch)
    hustle_list.status = HustleListStatus.OPEN
    await db.flush()

    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return SendResponse(
        list=serialize_hustle_list(refreshed),
        dispatch=serialize_dispatch(dispatch),
    )


async def publish_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    request: HustleListPublishRequest,
) -> PublishResponse:
    """Publish a hustle list to the marketplace."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)
    dispatch = HustleListDispatch(
        hustle_list_id=hustle_list.id,
        channel=HustleListDispatchChannel.MARKETPLACE,
        status=HustleListDispatchStatus.PENDING,
        sent_at=datetime.now(timezone.utc),
        expires_at=dispatch_expiry(request.expires_at),
    )
    db.add(dispatch)
    hustle_list.status = HustleListStatus.OPEN
    await db.flush()

    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return PublishResponse(
        list=serialize_hustle_list(refreshed),
        dispatches=[serialize_dispatch(dispatch)],
    )


async def withdraw_hustle_list_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    list_id: uuid.UUID,
    request: HustleListWithdrawRequest,
) -> HustleListDetailResponse:
    """Withdraw a hustle list from marketplace."""
    hustle_list = await get_buyer_list_or_404(db, user=user, list_id=list_id)

    pending_stmt = select(HustleListDispatch).where(
        HustleListDispatch.hustle_list_id == hustle_list.id,
        HustleListDispatch.status == HustleListDispatchStatus.PENDING,
    )
    pending_result = await db.execute(pending_stmt)
    for dispatch in pending_result.scalars().all():
        dispatch.status = HustleListDispatchStatus.WITHDRAWN
        dispatch.responded_at = datetime.now(timezone.utc)

    hustle_list.status = HustleListStatus.CANCELLED
    await db.flush()
    refreshed = await refresh_hustle_list(db, hustle_list.id)
    return serialize_hustle_list(refreshed)


async def get_marketplace_feed_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    place_id: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    cursor: str | None = None,
    limit: int = 20,
) -> list[HustleListSummaryResponse]:
    """Get marketplace feed for sellers."""
    from src.api.v1.marketplace.utils import parse_list_cursor

    cursor_created_at, cursor_id = parse_list_cursor(cursor)
    lists = await get_marketplace_feed_query(
        db,
        place_id=place_id,
        latitude=latitude,
        longitude=longitude,
        cursor_created_at=cursor_created_at,
        cursor_id=cursor_id,
        limit=limit,
    )
    return [
        HustleListSummaryResponse.model_validate(serialize_hustle_list(h).model_dump())
        for h in lists
    ]


async def list_dispatches_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    role: str | None = None,
    status_filter: str | None = None,
    cursor: str | None = None,
    limit: int = 20,
) -> list[DispatchSummaryResponse]:
    """List dispatches for buyer or seller."""
    if role and role not in {"buyer", "seller"}:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="role must be one of: buyer, seller.",
        )

    from src.api.v1.marketplace.utils import page_slice

    stmt = (
        select(HustleListDispatch)
        .options(
            selectinload(HustleListDispatch.target_seller),
            selectinload(HustleListDispatch.accepted_by_seller),
            selectinload(HustleListDispatch.hustle_list),
        )
        .order_by(HustleListDispatch.created_at.desc())
    )
    result = await db.execute(stmt)
    dispatches = list(result.scalars().all())

    if role == "buyer" or (not role and user.role.value in {"buyer", "admin"}):
        dispatches = [
            dispatch
            for dispatch in dispatches
            if dispatch.hustle_list.buyer_id == user.id
        ]
    else:
        seller_profile = await get_seller_profile_for_user(db, user)
        dispatches = [
            dispatch
            for dispatch in dispatches
            if dispatch.target_seller_id == seller_profile.id
            or dispatch.accepted_by_seller_id == seller_profile.id
        ]

    if status_filter is not None:
        dispatches = [
            dispatch
            for dispatch in dispatches
            if dispatch.status.value == status_filter
        ]

    if cursor:
        from src.api.v1.marketplace.utils import parse_list_cursor

        _, cursor_id = parse_list_cursor(cursor)
        if cursor_id:
            idx = next((i for i, d in enumerate(dispatches) if d.id == cursor_id), 0)
            dispatches = dispatches[idx + 1 :]

    start, end = page_slice(1, limit)
    return [serialize_dispatch(dispatch) for dispatch in dispatches[start:end]]


async def get_dispatch_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    dispatch_id: uuid.UUID,
) -> DispatchDetailResponse:
    """Get a specific dispatch with hustle list details."""
    stmt = (
        select(HustleListDispatch)
        .options(
            selectinload(HustleListDispatch.target_seller),
            selectinload(HustleListDispatch.accepted_by_seller),
            selectinload(HustleListDispatch.hustle_list).selectinload(HustleList.items),
            selectinload(HustleListDispatch.hustle_list)
            .selectinload(HustleList.dispatches)
            .selectinload(HustleListDispatch.target_seller),
            selectinload(HustleListDispatch.hustle_list)
            .selectinload(HustleList.dispatches)
            .selectinload(HustleListDispatch.accepted_by_seller),
            selectinload(HustleListDispatch.hustle_list).selectinload(
                HustleList.delivery_address
            ),
        )
        .where(HustleListDispatch.id == dispatch_id)
    )
    result = await db.execute(stmt)
    dispatch = result.scalar_one_or_none()
    if dispatch is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Dispatch not found.")

    seller_profile = None
    if user.role.value in {"seller", "admin"}:
        seller_stmt = select(SellerProfile.id).where(
            SellerProfile.user_id == user.id,
            SellerProfile.is_deleted.is_(False),
        )
        seller_result = await db.execute(seller_stmt)
        seller_id = seller_result.scalar_one_or_none()
        if seller_id is not None:
            seller_profile = seller_id

    is_buyer = dispatch.hustle_list.buyer_id == user.id
    is_seller = seller_profile is not None and (
        dispatch.target_seller_id == seller_profile
        or dispatch.accepted_by_seller_id == seller_profile
    )
    if not (is_buyer or is_seller):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this dispatch.",
        )

    return DispatchDetailResponse(
        dispatch=serialize_dispatch(dispatch),
        list=serialize_hustle_list(dispatch.hustle_list),
    )


async def decide_dispatch_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    dispatch_id: uuid.UUID,
    request: DispatchDecisionRequest,
) -> DispatchDecisionResponse:
    """Accept or decline a dispatch."""
    seller_profile = await get_seller_profile_for_user(db, user)
    stmt = (
        select(HustleListDispatch)
        .options(
            selectinload(HustleListDispatch.hustle_list).selectinload(HustleList.items),
            selectinload(HustleListDispatch.hustle_list)
            .selectinload(HustleList.dispatches)
            .selectinload(HustleListDispatch.target_seller),
            selectinload(HustleListDispatch.hustle_list)
            .selectinload(HustleList.dispatches)
            .selectinload(HustleListDispatch.accepted_by_seller),
            selectinload(HustleListDispatch.hustle_list).selectinload(
                HustleList.delivery_address
            ),
            selectinload(HustleListDispatch.target_seller),
            selectinload(HustleListDispatch.accepted_by_seller),
        )
        .where(HustleListDispatch.id == dispatch_id)
    )
    result = await db.execute(stmt)
    dispatch = result.scalar_one_or_none()
    if dispatch is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Dispatch not found.")

    if (
        dispatch.target_seller_id not in {None, seller_profile.id}
        and dispatch.accepted_by_seller_id != seller_profile.id
    ):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to act on this dispatch.",
        )

    if dispatch.status != HustleListDispatchStatus.PENDING:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="Only pending dispatches can be decided.",
        )

    if dispatch.expires_at is not None and dispatch.expires_at <= datetime.now(
        timezone.utc
    ):
        dispatch.status = HustleListDispatchStatus.EXPIRED
        dispatch.responded_at = datetime.now(timezone.utc)
        await db.flush()
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="This dispatch has expired."
        )

    if request.action == DispatchAction.ACCEPT:
        dispatch.status = HustleListDispatchStatus.ACCEPTED
        dispatch.accepted_by_seller = seller_profile
        dispatch.responded_at = datetime.now(timezone.utc)
        close_other_pending_dispatches(
            dispatch.hustle_list, keep_dispatch_id=dispatch.id
        )
        dispatch.hustle_list.status = HustleListStatus.ACCEPTED

        order_stmt = select(Order).where(
            Order.source_hustle_list_id == dispatch.hustle_list.id
        )
        order_result = await db.execute(order_stmt)
        order = order_result.scalar_one_or_none()
        if order is None:
            subtotal = await calculate_hustle_list_subtotal(db, dispatch.hustle_list.id)
            service_fee = (subtotal * Decimal("0.05")).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            order = Order(
                order_number=f"#{datetime.now(timezone.utc).strftime('%H%M%S')}-{dispatch.id.hex[:6]}",
                buyer_id=dispatch.hustle_list.buyer_id,
                seller_id=seller_profile.id,
                source_type=OrderSourceType.HUSTLE_LIST,
                source_hustle_list_id=dispatch.hustle_list.id,
                status=OrderStatus.PENDING_PAYMENT,
                pickup_location_id=None,
                delivery_address_snapshot_json=(
                    {
                        "address_text": (
                            dispatch.hustle_list.delivery_address.address_text
                            or dispatch.hustle_list.delivery_address.name
                        ),
                        "latitude": str(dispatch.hustle_list.delivery_address.latitude),
                        "longitude": str(
                            dispatch.hustle_list.delivery_address.longitude
                        ),
                    }
                    if dispatch.hustle_list.delivery_address is not None
                    else {}
                ),
                subtotal_amount=subtotal,
                delivery_fee_amount=Decimal(dispatch.hustle_list.delivery_fee),
                service_fee_amount=service_fee,
            )
            db.add(order)
            await db.flush()
        order_payload = serialize_order_reference(order)
    else:
        dispatch.status = HustleListDispatchStatus.DECLINED
        dispatch.responded_at = datetime.now(timezone.utc)
        order_payload = None

    await db.flush()
    return DispatchDecisionResponse(
        dispatch=serialize_dispatch(dispatch),
        order=order_payload,
    )
