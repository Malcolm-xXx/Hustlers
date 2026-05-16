import uuid

from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.core.exceptions import HTTPException
from src.models.auth import Address
from src.models.carts import Cart
from src.models.catalog import Product
from src.models.marketplace import ServiceAreaLocation
from src.models.orders import (
    Order,
    OrderComplaint,
    OrderItem,
    OrderReview,
    OrderStatusEvent,
)
from src.models.sellers import SellerProfile


async def get_order_or_404(db: AsyncSession, order_id: uuid.UUID) -> Order:
    """Fetch an order by ID or raise 404."""
    result = await db.execute(select(Order).where(Order.id == order_id).limit(1))
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order not found.")
    return order


async def seller_profile_for_user(
    db: AsyncSession, user: AuthenticatedActor
) -> SellerProfile:
    """Fetch seller profile for a user or raise 404."""
    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user.id).limit(1)
    )
    seller_profile = result.scalar_one_or_none()
    if seller_profile is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Seller profile not found."
        )
    return seller_profile


async def get_current_cart_or_none(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> "Cart | None":
    """Fetch the current active cart for a buyer."""
    from sqlalchemy import desc
    from src.models.carts import Cart, CartItem, CartStatus

    result = await db.execute(
        select(Cart)
        .options(
            selectinload(Cart.items)
            .selectinload(CartItem.product)
            .selectinload(Product.seller)
        )
        .where(Cart.buyer_id == user_id, Cart.status == CartStatus.ACTIVE)
        .order_by(desc(Cart.updated_at), desc(Cart.id))
        .limit(1)
    )
    cart = result.scalar_one_or_none()
    if cart is None or not cart.items:
        return None
    return cart


async def resolve_address(
    db: AsyncSession,
    user_id: uuid.UUID,
    address_id: uuid.UUID | None,
) -> Address | None:
    """Resolve address for a user - use specific address or default."""
    from sqlalchemy import desc

    if address_id is not None:
        result = await db.execute(
            select(Address)
            .where(Address.id == address_id, Address.user_id == user_id)
            .limit(1)
        )
        address = result.scalar_one_or_none()
        if address is not None:
            return address

    result = await db.execute(
        select(Address)
        .where(Address.user_id == user_id, Address.is_default.is_(True))
        .order_by(desc(Address.created_at))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def fetch_order_review(db: AsyncSession, order: Order) -> OrderReview | None:
    """Fetch order review if exists."""
    result = await db.execute(
        select(OrderReview).where(OrderReview.order_id == order.id).limit(1)
    )
    return result.scalar_one_or_none()


async def fetch_order_complaint(
    db: AsyncSession, order: Order
) -> OrderComplaint | None:
    """Fetch order complaint if exists."""
    result = await db.execute(
        select(OrderComplaint).where(OrderComplaint.order_id == order.id).limit(1)
    )
    return result.scalar_one_or_none()


async def get_order_items(db: AsyncSession, order_id: uuid.UUID) -> list[OrderItem]:
    """Fetch order items for an order."""
    result = await db.execute(
        select(OrderItem)
        .where(OrderItem.order_id == order_id)
        .order_by(OrderItem.created_at.asc())
    )
    return list(result.scalars().all())


async def get_order_status_events(
    db: AsyncSession, order_id: uuid.UUID
) -> list[OrderStatusEvent]:
    """Fetch status events for an order."""
    result = await db.execute(
        select(OrderStatusEvent)
        .where(OrderStatusEvent.order_id == order_id)
        .order_by(OrderStatusEvent.created_at.asc())
    )
    return list(result.scalars().all())


async def get_pickup_location(
    db: AsyncSession, pickup_location_id: uuid.UUID
) -> ServiceAreaLocation | None:
    """Fetch pickup location if exists."""
    result = await db.execute(
        select(ServiceAreaLocation)
        .where(ServiceAreaLocation.id == pickup_location_id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_order_item_by_id(
    db: AsyncSession, order_id: uuid.UUID, item_id: uuid.UUID
) -> OrderItem | None:
    """Fetch a specific order item."""
    result = await db.execute(
        select(OrderItem)
        .where(OrderItem.id == item_id, OrderItem.order_id == order_id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_product_by_id(db: AsyncSession, product_id: uuid.UUID) -> Product | None:
    """Fetch a product by ID."""
    result = await db.execute(select(Product).where(Product.id == product_id).limit(1))
    return result.scalar_one_or_none()
