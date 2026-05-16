import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.models.carts import Cart, CartItem, CartStatus
from src.models.catalog import (
    Product,
    ProductTag,
    SaleCampaign,
    SaleCampaignItem,
    SaleCampaignStatus,
)


async def get_cart_by_id(db: AsyncSession, cart_id: uuid.UUID) -> Cart | None:
    """Fetch a cart by ID."""
    result = await db.execute(select(Cart).where(Cart.id == cart_id).limit(1))
    return result.scalar_one_or_none()


async def get_active_cart_by_buyer(
    db: AsyncSession, buyer_id: uuid.UUID
) -> Cart | None:
    """Fetch the active cart for a buyer."""
    result = await db.execute(
        select(Cart)
        .where(Cart.buyer_id == buyer_id, Cart.status == CartStatus.ACTIVE)
        .order_by(desc(Cart.updated_at))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_or_create_current_cart(db: AsyncSession, user_id: uuid.UUID) -> Cart:
    """Get or create a current active cart for a user."""
    cart = await get_active_cart_by_buyer(db, user_id)
    if cart is None:
        cart = Cart(buyer_id=user_id, status=CartStatus.ACTIVE)
        db.add(cart)
        await db.flush()
    return cart


async def get_cart_items_with_details(
    db: AsyncSession, cart_ids: list[uuid.UUID]
) -> dict[uuid.UUID, list[dict[str, Any]]]:
    """Fetch cart items with product details, categories, images, tags, and active discounts.

    Returns a dict mapping cart_id -> list of item dicts with all needed data.
    Single query replaces: get_cart_items + get_products_by_ids + get_active_discount_map.
    """
    if not cart_ids:
        return {}

    now = datetime.now(timezone.utc)

    active_discount_subquery = (
        select(
            SaleCampaignItem.product_id,
            func.min(SaleCampaignItem.discounted_price).label("discounted_price"),
        )
        .join(SaleCampaign, SaleCampaignItem.campaign_id == SaleCampaign.id)
        .where(
            SaleCampaignItem.product_id == Product.id,
            SaleCampaign.status == SaleCampaignStatus.ACTIVE,
            SaleCampaign.starts_at <= now,
            SaleCampaign.ends_at >= now,
        )
        .group_by(SaleCampaignItem.product_id)
        .subquery()
    )

    statement = (
        select(
            CartItem,
            Product,
            active_discount_subquery.c.discounted_price.label("active_discount_price"),
        )
        .join(Product, CartItem.product_id == Product.id, isouter=True)
        .join(
            active_discount_subquery,
            CartItem.product_id == active_discount_subquery.c.product_id,
            isouter=True,
        )
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
        )
        .where(CartItem.cart_id.in_(cart_ids))
    )

    result = await db.execute(statement)
    rows = result.all()

    cart_items_map: dict[uuid.UUID, list[dict[str, Any]]] = {
        cid: [] for cid in cart_ids
    }

    for row in rows:
        cart_item = row[0]
        product = row[1]
        active_discount = row[2]

        item_dict: dict[str, Any] = {
            "cart_item": cart_item,
            "product": product,
            "active_discount": active_discount,
        }
        cart_items_map[cart_item.cart_id].append(item_dict)

    return cart_items_map


async def get_product_with_discount(
    db: AsyncSession, product_id: uuid.UUID
) -> tuple[Product | None, Decimal | None]:
    """Fetch product with its active discount price in a single query.

    Returns (product, discounted_price) where discounted_price is None if no active discount.
    Replaces: get_product_by_id + get_active_discount_map + current_product_price.
    """
    now = datetime.now(timezone.utc)

    active_discount_subquery = (
        select(
            SaleCampaignItem.product_id,
            func.min(SaleCampaignItem.discounted_price).label("discounted_price"),
        )
        .join(SaleCampaign, SaleCampaignItem.campaign_id == SaleCampaign.id)
        .where(
            SaleCampaignItem.product_id == product_id,
            SaleCampaign.status == SaleCampaignStatus.ACTIVE,
            SaleCampaign.starts_at <= now,
            SaleCampaign.ends_at >= now,
        )
        .group_by(SaleCampaignItem.product_id)
        .subquery()
    )

    statement = (
        select(Product, active_discount_subquery.c.discounted_price)
        .outerjoin(
            active_discount_subquery,
            Product.id == active_discount_subquery.c.product_id,
        )
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
        )
        .where(Product.id == product_id)
    )

    result = await db.execute(statement)
    row = result.one_or_none()

    if row is None:
        return None, None

    product = row[0]
    discount_price = row[1]
    return product, discount_price


async def get_saved_carts(
    db: AsyncSession,
    buyer_id: uuid.UUID,
    cursor_updated_at: datetime | None,
    cursor_id: uuid.UUID | None,
    limit: int,
) -> list[Cart]:
    """Fetch saved carts with cursor pagination."""
    statement = (
        select(Cart)
        .where(Cart.buyer_id == buyer_id, Cart.status == CartStatus.SAVED)
        .order_by(desc(Cart.updated_at), desc(Cart.id))
    )

    if cursor_updated_at is not None and cursor_id is not None:
        statement = statement.where(
            or_(
                Cart.updated_at < cursor_updated_at,
                and_(Cart.updated_at == cursor_updated_at, Cart.id < cursor_id),
            )
        )

    result = await db.execute(statement.limit(limit))
    return list(result.scalars().all())


async def get_saved_cart_by_id(
    db: AsyncSession, buyer_id: uuid.UUID, cart_id: uuid.UUID
) -> Cart | None:
    """Fetch a saved cart by ID for a buyer."""
    result = await db.execute(
        select(Cart)
        .where(
            Cart.id == cart_id,
            Cart.buyer_id == buyer_id,
            Cart.status == CartStatus.SAVED,
        )
        .limit(1)
    )
    return result.scalar_one_or_none()


async def update_active_carts_to_saved(
    db: AsyncSession, buyer_id: uuid.UUID, exclude_cart_id: uuid.UUID
) -> None:
    """Mark all active carts except one as saved."""
    from sqlalchemy import update

    await db.execute(
        update(Cart)
        .where(
            Cart.buyer_id == buyer_id,
            Cart.status == CartStatus.ACTIVE,
            Cart.id != exclude_cart_id,
        )
        .values(status=CartStatus.SAVED)
    )
