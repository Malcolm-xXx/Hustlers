import uuid

from fastapi import status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.carts.queries import (
    get_cart_items_with_details,
    get_or_create_current_cart,
    get_product_with_discount,
    get_saved_cart_by_id,
    get_saved_carts,
    update_active_carts_to_saved,
)
from src.api.v1.carts.schema import (
    CartItemRequest,
    CartItemUpdateRequest,
    CartResponse,
    SavedCartsPageResponse,
)
from src.api.v1.carts.utils import serialize_cart as serialize_cart_sync
from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
from src.core.exceptions import HTTPException
from src.models.carts import CartItem, CartStatus
from src.models.catalog import (
    ProductAvailabilityStatus,
    ProductPublishStatus,
    ProductStockStatus,
)


async def get_current_cart_service(
    db: AsyncSession, user: AuthenticatedActor
) -> CartResponse:
    """Get the current active cart for the user."""
    cart = await get_or_create_current_cart(db, user.id)
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def create_current_cart_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: CartItemRequest,
) -> CartResponse:
    """Add an item to the current cart."""
    cart = await get_or_create_current_cart(db, user.id)

    product, discounted_price = await get_product_with_discount(db, request.product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"product_id": ["Product not found."]},
        )

    if (
        product.publish_status != ProductPublishStatus.PUBLISHED
        or product.availability_status != ProductAvailabilityStatus.AVAILABLE
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"product_id": ["Product not found."]},
        )

    if product.stock_status == ProductStockStatus.OUT_OF_STOCK:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"product_id": ["Product is out of stock."]},
        )

    if request.quantity > product.stock_quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "quantity": [
                    f"Only {product.stock_quantity} item(s) currently available."
                ]
            },
        )

    base_price = product.base_price
    unit_price = discounted_price if discounted_price is not None else base_price

    result = await db.execute(
        select(CartItem).where(
            CartItem.cart_id == cart.id, CartItem.product_id == product.id
        )
    )
    item = result.scalar_one_or_none()

    if item is None:
        db.add(
            CartItem(
                cart_id=cart.id,
                product_id=product.id,
                quantity=request.quantity,
                unit_label_snapshot=product.unit_label,
                product_name_snapshot=product.name,
                unit_price_snapshot=base_price,
                discount_price_snapshot=discounted_price,
                line_total_snapshot=unit_price * request.quantity,
            )
        )
    else:
        next_quantity = item.quantity + request.quantity
        if next_quantity > product.stock_quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "quantity": [
                        "Requested quantity exceeds stock. "
                        f"Only {product.stock_quantity} item(s) available."
                    ]
                },
            )

        item.quantity = next_quantity
        item.unit_label_snapshot = product.unit_label
        item.product_name_snapshot = product.name
        item.unit_price_snapshot = base_price
        item.discount_price_snapshot = discounted_price
        item.line_total_snapshot = unit_price * next_quantity

    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def update_current_cart_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    item_id: uuid.UUID,
    request: CartItemUpdateRequest,
) -> CartResponse:
    """Update an item in the current cart."""
    cart = await get_or_create_current_cart(db, user.id)

    result = await db.execute(
        select(CartItem).where(CartItem.id == item_id, CartItem.cart_id == cart.id)
    )
    item = result.scalar_one_or_none()

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found.",
        )

    product, discounted_price = await get_product_with_discount(db, item.product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"product_id": ["Product not found."]},
        )

    if request.quantity > product.stock_quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "quantity": [
                    f"Only {product.stock_quantity} item(s) currently available."
                ]
            },
        )

    base_price = product.base_price
    effective_price = discounted_price if discounted_price is not None else base_price

    item.quantity = request.quantity
    item.unit_label_snapshot = product.unit_label
    item.product_name_snapshot = product.name
    item.unit_price_snapshot = base_price
    item.discount_price_snapshot = discounted_price
    item.line_total_snapshot = effective_price * request.quantity

    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def delete_current_cart_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    item_id: uuid.UUID,
) -> CartResponse:
    """Delete an item from the current cart."""
    cart = await get_or_create_current_cart(db, user.id)

    result = await db.execute(
        select(CartItem).where(CartItem.id == item_id, CartItem.cart_id == cart.id)
    )
    item = result.scalar_one_or_none()

    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found.",
        )

    await db.delete(item)
    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def empty_current_cart_service(
    db: AsyncSession, user: AuthenticatedActor
) -> CartResponse:
    """Empty all items from the current cart."""
    cart = await get_or_create_current_cart(db, user.id)
    await db.execute(delete(CartItem).where(CartItem.cart_id == cart.id))
    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def save_cart_service(db: AsyncSession, user: AuthenticatedActor) -> CartResponse:
    """Save the current cart."""
    cart = await get_or_create_current_cart(db, user.id)

    # Validate cart has items
    result = await db.execute(
        select(CartItem).where(CartItem.cart_id == cart.id).limit(1)
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot save an empty cart."
        )

    cart.status = CartStatus.SAVED
    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def list_saved_carts_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> SavedCartsPageResponse:
    """List saved carts with pagination."""
    safe_limit = min(max(limit, 1), 100)

    cursor_updated_at, cursor_id = (
        (None, None) if cursor is None else parse_cursor(cursor)
    )

    saved_carts = await get_saved_carts(
        db,
        user.id,
        cursor_updated_at,
        cursor_id,
        safe_limit + 1,
    )

    has_more = len(saved_carts) > safe_limit
    sliced_carts = saved_carts[:safe_limit]

    if not sliced_carts:
        return SavedCartsPageResponse(items=[], next_cursor=None, has_more=False)

    cart_ids = [cart.id for cart in sliced_carts]
    cart_items_map = await get_cart_items_with_details(db, cart_ids)

    payload_items: list[CartResponse] = []
    for cart in sliced_carts:
        items_data = cart_items_map.get(cart.id, [])
        payload_items.append(serialize_cart_sync(cart, items_data))

    next_cursor: str | None = None
    if has_more and sliced_carts:
        tail_cart = sliced_carts[-1]
        next_cursor = encode_cursor(tail_cart.updated_at, tail_cart.id)

    return SavedCartsPageResponse(
        items=payload_items,
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def restore_saved_cart_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cart_id: uuid.UUID,
) -> CartResponse:
    """Restore a saved cart to be the current cart."""
    cart = await get_saved_cart_by_id(db, user.id, cart_id)
    if cart is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Saved cart not found.",
        )

    await update_active_carts_to_saved(db, user.id, cart.id)

    cart.status = CartStatus.ACTIVE
    await db.flush()
    cart_items_map = await get_cart_items_with_details(db, [cart.id])
    items_data = cart_items_map.get(cart.id, [])
    return serialize_cart_sync(cart, items_data)


async def delete_saved_cart_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cart_id: uuid.UUID,
) -> None:
    """Delete a saved cart."""
    cart = await get_saved_cart_by_id(db, user.id, cart_id)
    if cart is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Saved cart not found.",
        )

    await db.delete(cart)
    await db.flush()
