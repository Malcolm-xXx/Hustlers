import uuid
from decimal import Decimal

from fastapi import status

from src.api.v1.carts.schema import (
    CartItemResponse,
    CartResponse,
    ProductCardItem,
    ProductSellerSummary,
)
from src.api.v1.shared.utils.currency import format_money
from src.core.exceptions import HTTPException
from src.models.carts import CartStatus
from src.models.catalog import Product, ProductStockStatus


def parse_uuid_or_not_found(raw: str, *, message: str) -> uuid.UUID:
    """Parse UUID from string or raise 404."""
    try:
        return uuid.UUID(raw)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=message
        ) from exc


def serialize_product_card(
    product: Product,
    discounted_price: Decimal | None,
) -> ProductCardItem:
    """Serialize a product to ProductCardItem."""
    image_url: str | None = None
    if product.images:
        sorted_images = sorted(
            product.images,
            key=lambda image: (
                not image.is_primary,
                image.sort_order,
                image.created_at,
            ),
        )
        image_url = sorted_images[0].image_file_url

    is_low_stock = product.stock_status == ProductStockStatus.LOW_STOCK or (
        0 < product.stock_quantity <= product.low_stock_threshold
    )

    return ProductCardItem(
        id=product.id,
        name=product.name,
        unit_label=product.unit_label,
        seller=ProductSellerSummary(
            id=product.seller_id,
            store_name=product.seller.store_name,
        ),
        base_price=format_money(product.base_price),
        discounted_price=(
            format_money(discounted_price) if discounted_price is not None else None
        ),
        is_on_sale=(
            discounted_price is not None and discounted_price < product.base_price
        ),
        is_low_stock=is_low_stock,
        image_url=image_url,
    )


def fallback_product_card(item) -> ProductCardItem:
    """Serialize a fallback product card from cart item snapshot."""
    return ProductCardItem(
        id=item.product_id,
        name=item.product_name_snapshot,
        unit_label=item.unit_label_snapshot,
        seller=ProductSellerSummary(id=item.product_id, store_name=""),
        base_price=format_money(item.unit_price_snapshot),
        discounted_price=(
            format_money(item.discount_price_snapshot)
            if item.discount_price_snapshot is not None
            else None
        ),
        is_on_sale=item.discount_price_snapshot is not None,
        is_low_stock=False,
        image_url=None,
    )


def serialize_cart(
    cart,
    items_data: list[dict],
) -> CartResponse:
    """Serialize cart with items to CartResponse.

    items_data: list of dicts with keys: cart_item, product, active_discount
    """
    items_payload: list[CartItemResponse] = []
    subtotal = Decimal("0.00")

    for item_data in items_data:
        cart_item = item_data["cart_item"]
        product = item_data["product"]
        active_discount = item_data["active_discount"]

        subtotal += cart_item.line_total_snapshot

        if product is None:
            product_payload = fallback_product_card(cart_item)
        else:
            product_payload = serialize_product_card(product, active_discount)

        items_payload.append(
            CartItemResponse(
                id=cart_item.id,
                product=product_payload,
                quantity=cart_item.quantity,
            )
        )

    subtotal_str = format_money(subtotal)
    return CartResponse(
        id=cart.id,
        status=CartStatus(cart.status.value),
        items=items_payload,
        subtotal_amount=subtotal_str,
    )


async def serialize_cart_async(db, cart_id: uuid.UUID) -> CartResponse:
    """Backward compatible async wrapper for orders/service.py.

    Takes (db, cart_id) instead of (cart, items_data).
    """
    from src.api.v1.carts.queries import get_cart_by_id, get_cart_items_with_details

    cart = await get_cart_by_id(db, cart_id)
    if cart is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart not found.",
        )
    cart_items_map = await get_cart_items_with_details(db, [cart_id])
    items_data = cart_items_map.get(cart_id, [])
    return serialize_cart(cart, items_data)
