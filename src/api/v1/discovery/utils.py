from __future__ import annotations

import math
import uuid
from collections.abc import Sequence
from datetime import datetime, timezone
from decimal import Decimal
from typing import Protocol, TypeVar

from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.discovery.queries import load_locations_by_ids
from src.api.v1.discovery.schema import (
    LocationSummaryResponse,
    ProductCardResponse,
    SellerCardResponse,
)
from src.api.v1.shared.schema import ProductSellerSummaryResponse
from src.api.v1.shared.utils.currency import format_money
from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
from src.core.exceptions import HTTPException
from src.models.auth import User
from src.models.catalog import (
    Product,
    ProductImage,
    ProductStockStatus,
    SaleCampaignStatus,
)
from src.models.marketplace import ServiceAreaLocation
from src.models.sellers import SellerPresenceStatus, SellerProfile
from src.utils.permissions import can_do_buyer_actions


class _CursorItem(Protocol):
    created_at: datetime
    id: uuid.UUID


TItem = TypeVar("TItem", bound=_CursorItem)


def ensure_buyer_access(user: User) -> None:
    if not can_do_buyer_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Buyer role is required to access this endpoint.",
        )


def normalize_optional_text(value: str | None, *, lower: bool = False) -> str | None:
    if value is None:
        return None

    normalized_value = value.strip()
    if not normalized_value:
        return None

    return normalized_value.lower() if lower else normalized_value


def paginate_items(
    items: Sequence[TItem],
    cursor: str | None,
    limit: int,
) -> tuple[list[TItem], str | None, bool]:
    safe_limit = min(max(limit, 1), 100)
    ordered_items = sorted(
        items,
        key=lambda item: (item.created_at, item.id),
        reverse=True,
    )

    if cursor is not None:
        cursor_created_at, cursor_id = parse_cursor(cursor)
        ordered_items = [
            item
            for item in ordered_items
            if item.created_at < cursor_created_at
            or (item.created_at == cursor_created_at and item.id < cursor_id)
        ]

    page_items = ordered_items[: safe_limit + 1]
    has_more = len(page_items) > safe_limit
    visible_items = page_items[:safe_limit]

    next_cursor: str | None = None
    if has_more and visible_items:
        tail_item = visible_items[-1]
        next_cursor = encode_cursor(tail_item.created_at, tail_item.id)

    return visible_items, next_cursor, has_more


def best_discounted_price(product: Product) -> Decimal | None:
    now = datetime.now(timezone.utc)
    active_sale_items = [
        item
        for item in product.sale_campaign_items
        if item.campaign is not None
        and item.campaign.status == SaleCampaignStatus.ACTIVE
        and item.campaign.starts_at <= now
        and item.campaign.ends_at >= now
    ]
    if not active_sale_items:
        return None
    return min(
        active_sale_items, key=lambda item: item.discounted_price
    ).discounted_price


def ordered_product_images(product: Product) -> list[ProductImage]:
    return sorted(
        product.images,
        key=lambda image: (not image.is_primary, image.sort_order, image.created_at),
    )


def product_category_matches(product: Product, category_key: str) -> bool:
    category_key_lower = category_key.strip().lower()
    category_aliases = {
        "fresh_market": {"fresh market", "fresh-market", "fresh", "market"},
        "grains": {"grains", "staples"},
        "oil_spices": {"oil", "oils", "spice", "spices", "oil-spices", "oil/spices"},
        "breakfast": {"breakfast"},
        "drinks_snacks": {"drinks", "snacks", "drink", "snack", "drinks-snacks"},
    }

    expected_tokens = category_aliases.get(category_key_lower, {category_key_lower})
    for token in expected_tokens:
        for product_category in product.categories:
            category_name = product_category.name.lower()
            category_slug = product_category.slug.lower()
            parent = product_category.parent
            parent_name = parent.name.lower() if parent else ""
            parent_slug = parent.slug.lower() if parent else ""
            match_targets = {category_name, category_slug, parent_name, parent_slug}
            if any(token in target for target in match_targets if target):
                return True
    return False


def seller_matches_query(seller: SellerProfile, query: str) -> bool:
    query_lower = query.lower()
    if query_lower in seller.store_name.lower():
        return True
    if query_lower in seller.user.full_name.lower():
        return True
    for seller_tag in seller.seller_tags:
        if seller_tag.tag is not None and query_lower in seller_tag.tag.name.lower():
            return True
    return False


def product_matches_query(product: Product, query: str) -> bool:
    query_lower = query.lower()
    if query_lower in product.name.lower():
        return True
    for product_category in product.categories:
        if query_lower in product_category.name.lower():
            return True
        if query_lower in product_category.slug.lower():
            return True
    return False


def location_matches_query(location: ServiceAreaLocation, query: str) -> bool:
    query_lower = query.lower()
    return (
        query_lower in location.name.lower()
        or query_lower in location.address_text.lower()
    )


def distance_km(origin: tuple[float, float], destination: tuple[float, float]) -> float:
    origin_lat = math.radians(origin[0])
    origin_lon = math.radians(origin[1])
    dest_lat = math.radians(destination[0])
    dest_lon = math.radians(destination[1])

    delta_lat = dest_lat - origin_lat
    delta_lon = dest_lon - origin_lon
    a = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(origin_lat) * math.cos(dest_lat) * math.sin(delta_lon / 2) ** 2
    )
    return 6371.0088 * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


async def seller_distance_map(
    db: AsyncSession,
    sellers: Sequence[SellerProfile],
    origin_coordinates: tuple[float, float] | None,
) -> dict[uuid.UUID, float]:
    if origin_coordinates is None:
        return {}

    location_ids = {
        seller.presence.current_location_id
        for seller in sellers
        if seller.presence is not None
        and seller.presence.current_location_id is not None
    }
    locations = await load_locations_by_ids(db, location_ids)

    distances: dict[uuid.UUID, float] = {}
    for seller in sellers:
        presence = seller.presence
        if presence is None or presence.current_location_id is None:
            continue
        location = locations.get(presence.current_location_id)
        if location is None:
            continue
        distances[seller.id] = distance_km(
            origin_coordinates,
            (float(location.latitude), float(location.longitude)),
        )
    return distances


async def product_distance_map(
    db: AsyncSession,
    products: Sequence[Product],
    origin_coordinates: tuple[float, float] | None,
) -> dict[uuid.UUID, float]:
    if origin_coordinates is None:
        return {}

    location_ids = {
        product.seller.presence.current_location_id
        for product in products
        if product.seller.presence is not None
        and product.seller.presence.current_location_id is not None
    }
    locations = await load_locations_by_ids(db, location_ids)

    distances: dict[uuid.UUID, float] = {}
    for product in products:
        presence = product.seller.presence
        if presence is None or presence.current_location_id is None:
            continue
        location = locations.get(presence.current_location_id)
        if location is None:
            continue
        distances[product.id] = distance_km(
            origin_coordinates,
            (float(location.latitude), float(location.longitude)),
        )
    return distances


async def location_distance_map(
    locations: Sequence[ServiceAreaLocation],
    origin_coordinates: tuple[float, float] | None,
) -> dict[uuid.UUID, float]:
    if origin_coordinates is None:
        return {}

    return {
        location.id: distance_km(
            origin_coordinates,
            (float(location.latitude), float(location.longitude)),
        )
        for location in locations
    }


def seller_card(
    seller: SellerProfile,
    *,
    favorite_seller_ids: set[uuid.UUID],
    distance_km: float | None,
) -> SellerCardResponse:
    presence = seller.presence
    tags = [
        seller_tag.tag.name
        for seller_tag in seller.seller_tags
        if seller_tag.tag is not None and seller_tag.tag.is_active
    ]

    return SellerCardResponse(
        id=seller.id,
        store_name=seller.store_name,
        profile_image=seller.profile_image_url,
        status=(
            presence.status.value
            if presence is not None
            else SellerPresenceStatus.OFFLINE.value
        ),
        rating=float(seller.avg_rating),
        rating_count=seller.rating_count,
        completed_orders_count=seller.completed_orders_count,
        distance_km=round(distance_km, 1) if distance_km is not None else None,
        tags=tags,
        is_favorite=seller.id in favorite_seller_ids,
    )


def product_card(
    product: Product,
) -> ProductCardResponse:
    discounted_price = best_discounted_price(product)
    ordered_images = ordered_product_images(product)
    first_image = ordered_images[0] if ordered_images else None

    return ProductCardResponse(
        id=product.id,
        name=product.name,
        unit_label=product.unit_label,
        seller=ProductSellerSummaryResponse(
            id=product.seller.id,
            store_name=product.seller.store_name,
        ),
        base_price=format_money(product.base_price),
        discounted_price=format_money(discounted_price)
        if discounted_price is not None
        else None,
        is_on_sale=discounted_price is not None
        and discounted_price < product.base_price,
        is_low_stock=(
            product.stock_status == ProductStockStatus.LOW_STOCK
            or 0 < product.stock_quantity <= product.low_stock_threshold
        ),
        image_url=first_image.image_file_url if first_image is not None else None,
        categories=[category.name for category in product.categories],
    )


def location_card(
    location: ServiceAreaLocation,
    *,
    distance_km: float | None,
) -> LocationSummaryResponse:
    return LocationSummaryResponse(
        id=location.id,
        name=location.name,
        address_text=location.address_text,
        distance_km=round(distance_km, 1) if distance_km is not None else None,
        rating=0.0,
        seller_count=0,
    )


def filter_sellers(
    sellers: Sequence[SellerProfile],
    *,
    search_query: str | None,
    filter_key: str | None,
    favorite_seller_ids: set[uuid.UUID],
) -> list[SellerProfile]:
    filtered_sellers = list(sellers)

    if search_query:
        filtered_sellers = [
            seller
            for seller in filtered_sellers
            if seller_matches_query(seller, search_query)
        ]

    if filter_key == "favorites":
        filtered_sellers = [
            seller for seller in filtered_sellers if seller.id in favorite_seller_ids
        ]
    elif filter_key == "in_market":
        filtered_sellers = [
            seller
            for seller in filtered_sellers
            if seller.presence is not None
            and seller.presence.status == SellerPresenceStatus.AT_MARKET
        ]
    elif filter_key == "nearby":
        filtered_sellers = [
            seller
            for seller in filtered_sellers
            if seller.is_accepting_orders
            and seller.presence is not None
            and seller.presence.status
            in {SellerPresenceStatus.ACTIVE, SellerPresenceStatus.AT_MARKET}
        ]

    return filtered_sellers


def filter_products(
    products: Sequence[Product],
    *,
    search_query: str | None,
    category_key: str | None,
    filter_key: str | None,
    favorite_product_ids: set[uuid.UUID],
) -> list[Product]:
    filtered_products = list(products)

    if search_query:
        filtered_products = [
            product
            for product in filtered_products
            if product_matches_query(product, search_query)
        ]

    if category_key:
        filtered_products = [
            product
            for product in filtered_products
            if product_category_matches(product, category_key)
        ]

    if filter_key == "promos":
        filtered_products = [
            product
            for product in filtered_products
            if best_discounted_price(product) is not None
        ]
    elif filter_key == "favorites":
        filtered_products = [
            product
            for product in filtered_products
            if product.id in favorite_product_ids
        ]

    return filtered_products


def filter_locations(
    locations: Sequence[ServiceAreaLocation],
    *,
    query: str | None,
) -> list[ServiceAreaLocation]:
    if not query:
        return list(locations)
    return [
        location for location in locations if location_matches_query(location, query)
    ]


def filter_by_distance(
    items: Sequence[TItem],
    *,
    distance_map: dict[uuid.UUID, float],
    distance_limit: Decimal | None,
    origin_coordinates: tuple[float, float] | None,
) -> list[TItem]:
    if distance_limit is None or origin_coordinates is None:
        return list(items)

    safe_limit = float(distance_limit)
    return [
        item
        for item in items
        if (distance := distance_map.get(item.id)) is not None
        and distance <= safe_limit
    ]
