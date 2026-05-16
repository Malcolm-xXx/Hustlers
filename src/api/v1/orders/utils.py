"""Order-specific helper utilities."""

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from src.api.v1.auth.schema import (
    AddressResponse,
    CoordinatesResponse,
    LocationResponse,
)
from src.api.v1.shared.serializers import build_user_summary
from src.api.v1.orders.queries import (
    fetch_order_complaint,
    fetch_order_review,
    get_order_items,
    get_order_status_events,
    get_pickup_location,
)
from src.api.v1.shared.schema import LocationSummary, SellerCardResponse
from src.api.v1.shared.utils.currency import format_money
from src.core.exceptions import HTTPException
from src.models.auth import Address, User
from src.models.orders import Order
from src.models.orders import OrderItemFulfillmentStatus
from src.models.payments import PaymentStatus as PaymentStatusResponse
from src.models.sellers import SellerProfile
from fastapi import status as http_status


def next_order_number() -> str:
    """Generate next order number."""
    return f"#{datetime.now(timezone.utc).strftime('%H%M%S%f')[-6:]}"


def order_total_amount(order: Order) -> Decimal:
    """Calculate total order amount."""
    return order.subtotal_amount + order.delivery_fee_amount + order.service_fee_amount


def delivery_address_text(order: Order, delivery_address: Address | None) -> str:
    """Get delivery address text from order snapshot or address."""
    snapshot = order.delivery_address_snapshot_json or {}
    if snapshot.get("address_text"):
        return str(snapshot["address_text"])
    if delivery_address is not None:
        return delivery_address.address_text or delivery_address.name
    return ""


def address_response(address: Address) -> AddressResponse:
    """Build address response."""
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


def user_summary(user):
    """Build user summary response."""
    return build_user_summary(user)


def seller_card(seller: SellerProfile) -> SellerCardResponse:
    """Build seller card response."""
    return SellerCardResponse(
        id=seller.id,
        store_name=seller.store_name,
        profile_image=seller.profile_image_url,
        status="active" if seller.is_accepting_orders else "offline",
        rating=float(seller.avg_rating) if seller.avg_rating is not None else None,
        rating_count=seller.rating_count,
        completed_orders_count=seller.completed_orders_count,
        distance_km=None,
        tags=[],
        is_favorite=False,
    )


def location_summary(location) -> LocationSummary:
    """Build location summary response."""
    return LocationSummary(
        id=location.id,
        name=location.name,
        address_text=location.address_text,
    )


def order_item_response(item):
    """Build order item response."""
    from src.api.v1.orders.schema import OrderItemResponse

    return OrderItemResponse(
        id=item.id,
        display_name=item.display_name,
        quantity=format_money(item.quantity),
        unit_label=item.unit_label,
        base_unit_price=format_money(item.base_unit_price),
        final_unit_price=format_money(item.final_unit_price),
        line_total=format_money(item.line_total),
        fulfillment_status=OrderItemFulfillmentStatus(item.fulfillment_status.value),
    )


def status_event_response(event):
    """Build status event response."""
    from src.api.v1.orders.schema import OrderStatusEventResponse

    return OrderStatusEventResponse(
        status=event.status.value,
        actor_user_id=event.actor_user_id,
        note=event.note,
        created_at=event.created_at,
    )


def ensure_order_access(*, user, order: Order) -> None:
    """Check if user has access to order."""
    if user.id == order.buyer_id:
        return
    if getattr(user, "is_staff", False) or getattr(user, "is_superuser", False):
        return
    raise HTTPException(
        status_code=http_status.HTTP_403_FORBIDDEN,
        detail="You do not have permission to view this order.",
    )


async def serialize_order_detail(db, order: Order, *, buyer=None, seller=None):
    """Serialize order to detail response."""
    from src.api.v1.orders.schema import (
        OrderDetailResponse,
        OrderReviewResponse,
        OrderComplaintResponse,
    )
    from src.models.orders import OrderReviewTag, OrderComplaintTag

    if buyer is None:
        buyer_result = await db.execute(
            select(User).where(User.id == order.buyer_id).limit(1)
        )
        buyer = buyer_result.scalar_one_or_none()
    if buyer is None:
        raise HTTPException(http_status.HTTP_404_NOT_FOUND, detail="Buyer not found.")

    if seller is None:
        seller_result = await db.execute(
            select(SellerProfile).where(SellerProfile.id == order.seller_id).limit(1)
        )
        seller = seller_result.scalar_one_or_none()

    delivery_address = None

    pickup_location = None
    if order.pickup_location_id is not None:
        pickup_location = await get_pickup_location(db, order.pickup_location_id)

    items = await get_order_items(db, order.id)
    status_events = await get_order_status_events(db, order.id)

    review = await fetch_order_review(db, order)
    review_payload = None
    if review is not None:
        review_tags_result = await db.execute(
            select(OrderReviewTag)
            .options(selectinload(OrderReviewTag.review_tag))
            .where(OrderReviewTag.order_review_id == review.id)
        )
        review_tags = [
            row.review_tag.name for row in review_tags_result.scalars().all()
        ]
        review_payload = OrderReviewResponse(
            status=("submitted" if review.submitted_at is not None else "pending"),
            rating=review.rating,
            tags=review_tags,
            comment=review.comment or "",
            submitted_at=review.submitted_at,
        )

    complaint = await fetch_order_complaint(db, order)
    complaint_payload = None
    if complaint is not None:
        complaint_tags_result = await db.execute(
            select(OrderComplaintTag)
            .options(selectinload(OrderComplaintTag.complaint_tag))
            .where(OrderComplaintTag.order_complaint_id == complaint.id)
        )
        complaint_tags = [
            row.complaint_tag.name for row in complaint_tags_result.scalars().all()
        ]
        complaint_payload = OrderComplaintResponse(
            tags=complaint_tags,
            comment=complaint.comment or "",
            created_at=complaint.created_at,
        )

    summary = order_summary(
        order=order,
        buyer=buyer,
        seller=seller,
        delivery_address=delivery_address,
        items_count=len(items),
    )
    return OrderDetailResponse(
        **summary.model_dump(),
        pickup_location=(
            location_summary(pickup_location) if pickup_location is not None else None
        ),
        delivery_address=(
            address_response(delivery_address) if delivery_address is not None else None
        ),
        special_instructions=order.special_instructions,
        status_events=[status_event_response(event) for event in status_events],
        items=[order_item_response(item) for item in items],
        review=review_payload,
        complaint=complaint_payload,
    )


def order_summary(*, order, buyer, seller, delivery_address, items_count):
    """Build order summary response."""
    from src.api.v1.orders.schema import OrderSummaryResponse

    return OrderSummaryResponse(
        id=order.id,
        order_number=order.order_number,
        status=order.status.value,
        payment_status=(
            PaymentStatusResponse.PENDING
            if order.status.value == "pending_payment"
            else PaymentStatusResponse.SUCCEEDED
        ),
        buyer=user_summary(buyer),
        seller=seller_card(seller) if seller is not None else None,
        eta_minutes=order.seller_eta_minutes,
        delivery_address_text=delivery_address_text(order, delivery_address),
        items_count=items_count,
        total_amount=format_money(order_total_amount(order)),
        created_at=order.created_at,
    )


async def order_page(db, *, filters, cursor, limit):
    """Paginate orders with filters."""
    from sqlalchemy import and_, desc, func, or_, select
    from src.api.v1.orders.schema import OrderPageResponse
    from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
    from src.models.orders import Order, OrderItem
    from src.models.auth import User
    from src.models.sellers import SellerProfile

    safe_limit = min(max(limit, 1), 100)
    where_clause = list(filters)

    count_result = await db.execute(
        select(func.count()).select_from(Order).where(and_(*where_clause))
    )
    total_count = int(count_result.scalar_one())

    statement = (
        select(Order)
        .where(and_(*where_clause))
        .order_by(desc(Order.created_at), desc(Order.id))
    )
    if cursor is not None:
        cursor_created_at, cursor_id = parse_cursor(cursor)
        statement = statement.where(
            or_(
                Order.created_at < cursor_created_at,
                and_(Order.created_at == cursor_created_at, Order.id < cursor_id),
            )
        )

    orders_result = await db.execute(statement.limit(safe_limit + 1))
    orders = list(orders_result.scalars().all())
    has_more = len(orders) > safe_limit
    orders = orders[:safe_limit]

    if not orders:
        return OrderPageResponse(
            items=[], count=total_count, next_cursor=None, has_more=False
        )

    order_ids = [order.id for order in orders]
    buyer_ids = {order.buyer_id for order in orders}
    seller_ids = {order.seller_id for order in orders}

    buyer_result = await db.execute(select(User).where(User.id.in_(buyer_ids)))
    buyers = {user.id: user for user in buyer_result.scalars().all()}

    seller_result = await db.execute(
        select(SellerProfile).where(SellerProfile.id.in_(seller_ids))
    )
    sellers = {seller.id: seller for seller in seller_result.scalars().all()}

    count_result = await db.execute(
        select(OrderItem.order_id, func.count(OrderItem.id))
        .where(OrderItem.order_id.in_(order_ids))
        .group_by(OrderItem.order_id)
    )
    item_counts = {row[0]: int(row[1]) for row in count_result.all()}

    payload_items = [
        order_summary(
            order=order,
            buyer=buyers[order.buyer_id],
            seller=sellers.get(order.seller_id),
            delivery_address=None,
            items_count=item_counts.get(order.id, 0),
        )
        for order in orders
    ]

    next_cursor = (
        encode_cursor(orders[-1].created_at, orders[-1].id) if has_more else None
    )
    return OrderPageResponse(
        items=payload_items,
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def wallet_summary(db, user_id):
    """Build wallet summary response."""
    from src.api.v1.payments.schema import WalletSummaryResponse
    from src.models.payments import Wallet

    result = await db.execute(select(Wallet).where(Wallet.user_id == user_id).limit(1))
    wallet = result.scalar_one_or_none()
    if wallet is None:
        return WalletSummaryResponse()
    return WalletSummaryResponse(
        wallet_id=wallet.id,
        currency_code=wallet.currency_code,
        available_balance=format_money(wallet.available_balance),
        pending_balance=format_money(wallet.pending_balance),
    )


async def serialize_cart_groups(cart) -> list:
    """Serialize cart items into order groups by seller."""
    from src.api.v1.carts.schema import CartGroup, CartGroupItem, ProductSellerSummary

    grouped: dict = {}

    for item in cart.items:
        product = item.product
        if product is None:
            continue
        seller = product.seller
        if seller.id not in grouped:
            grouped[seller.id] = (seller, [], Decimal("0.00"))
        seller_entry, items, subtotal = grouped[seller.id]
        items.append(
            CartGroupItem(
                product_id=product.id,
                quantity=item.quantity,
                line_total=format_money(item.line_total_snapshot),
            )
        )
        grouped[seller.id] = (seller_entry, items, subtotal + item.line_total_snapshot)

    payload = []
    for seller, items, subtotal in grouped.values():
        payload.append(
            CartGroup(
                seller=ProductSellerSummary(
                    id=seller.id,
                    store_name=seller.store_name,
                ),
                items=items,
                subtotal_amount=format_money(subtotal),
            )
        )
    return payload
