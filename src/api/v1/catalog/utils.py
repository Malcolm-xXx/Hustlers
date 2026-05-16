"""Catalog utility functions."""

import re
import uuid
from collections.abc import Sequence
from datetime import datetime, timezone
from decimal import Decimal
from typing import Callable, Literal, Protocol, TypeVar

from fastapi import Request, status

from src.api.v1.catalog.schema import (
    CategoryResponse,
    ProductCardResponse,
    ProductDetailResponse,
    ProductTagResponse,
    SaleCampaignItemSummaryResponse,
    SaleCampaignResponse,
    SaleCampaignStatus,
    SaleCampaignType,
    SellerTagResponse,
    TagResponse,
)
from src.api.v1.shared.schema import ProductSellerSummaryResponse
from src.api.v1.shared.utils.currency import format_decimal, format_money
from src.core.exceptions import HTTPException
from src.models.catalog import (
    Product,
    ProductStockStatus,
    SaleCampaign,
    SaleCampaignItem,
    SellerTag,
    Tag,
)


CursorValue = datetime | Decimal | int


class _HasId(Protocol):
    id: uuid.UUID


TItem = TypeVar("TItem", bound=_HasId)


def product_image_url(
    request: Request | None, image_file_url: str | None
) -> str | None:
    if not image_file_url:
        return None
    if image_file_url.startswith("http://") or image_file_url.startswith("https://"):
        return image_file_url
    if request is None:
        return image_file_url
    return str(request.base_url).rstrip("/") + "/" + image_file_url.lstrip("/")


def best_discounted_price(product: Product) -> Decimal | None:
    active_sale_items = getattr(product, "active_sale_items", None)
    if active_sale_items:
        return active_sale_items[0].discounted_price

    sale_items = [
        item
        for item in product.sale_campaign_items
        if item.campaign.status == SaleCampaignStatus.ACTIVE
        and item.campaign.starts_at <= datetime.now(timezone.utc)
        and item.campaign.ends_at >= datetime.now(timezone.utc)
    ]
    if not sale_items:
        return None
    sale_items.sort(key=lambda item: item.discounted_price)
    return sale_items[0].discounted_price


def product_low_stock(product: Product) -> bool:
    return product.stock_status == ProductStockStatus.LOW_STOCK or (
        0 < product.stock_quantity <= product.low_stock_threshold
    )


def ordered_categories(categories: Sequence) -> list:
    return sorted(
        categories,
        key=lambda category: (
            category.display_order,
            category.name.lower(),
            str(category.id),
        ),
    )


def product_category_names(product: Product) -> list[str]:
    return [category.name for category in ordered_categories(product.categories)]


def normalize_slug(value: str) -> str:
    """Normalize string to URL-safe slug."""
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:240] or "item"


def is_after_cursor(
    current_value: datetime | Decimal | int,
    current_id: uuid.UUID,
    cursor_value: datetime | Decimal | int,
    cursor_id: uuid.UUID,
    *,
    descending: bool,
) -> bool:
    """Check if current_value is after cursor_value."""
    if isinstance(current_value, datetime) and isinstance(cursor_value, datetime):
        if descending:
            return current_value < cursor_value or (
                current_value == cursor_value and current_id.int < cursor_id.int
            )
        return current_value > cursor_value or (
            current_value == cursor_value and current_id.int > cursor_id.int
        )
    if isinstance(current_value, Decimal) and isinstance(cursor_value, Decimal):
        if descending:
            return current_value < cursor_value or (
                current_value == cursor_value and current_id.int < cursor_id.int
            )
        return current_value > cursor_value or (
            current_value == cursor_value and current_id.int > cursor_id.int
        )
    if isinstance(current_value, int) and isinstance(cursor_value, int):
        if descending:
            return current_value < cursor_value or (
                current_value == cursor_value and current_id.int < cursor_id.int
            )
        return current_value > cursor_value or (
            current_value == cursor_value and current_id.int > cursor_id.int
        )
    raise ValueError(
        "Cursor value types must match and be one of datetime, Decimal, or int."
    )


def encode_cursor(sort_key: str, value: CursorValue, item_id: uuid.UUID) -> str:
    if isinstance(value, datetime):
        encoded_value = value.isoformat()
    else:
        encoded_value = str(value)
    return f"{sort_key}|{encoded_value}|{item_id}"


def decode_cursor(cursor: str) -> tuple[str, str, uuid.UUID]:
    try:
        sort_key, value_raw, item_id_raw = cursor.split("|", 2)
        return sort_key, value_raw, uuid.UUID(item_id_raw)
    except (ValueError, TypeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        ) from exc


def parse_cursor_value(
    value_raw: str, kind: Literal["datetime", "decimal", "int"]
) -> CursorValue:
    try:
        if kind == "datetime":
            parsed = datetime.fromisoformat(value_raw)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed
        if kind == "decimal":
            return Decimal(value_raw)
        return int(value_raw)
    except (TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        ) from exc


def paginate_items(
    items: Sequence[TItem],
    *,
    limit: int,
    cursor: str | None,
    sort_key: str,
    key_fn: Callable[[TItem], CursorValue],
    key_kind: Literal["datetime", "decimal", "int"],
    descending: bool,
) -> tuple[list[TItem], int, str | None, bool]:
    ordered = sorted(
        items, key=lambda item: (key_fn(item), item.id.int), reverse=descending
    )

    total_count = len(ordered)
    if cursor is not None:
        cursor_sort, cursor_value_raw, cursor_id = decode_cursor(cursor)
        if cursor_sort != sort_key:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid cursor.",
            )
        cursor_value = parse_cursor_value(cursor_value_raw, key_kind)
        ordered = [
            item
            for item in ordered
            if is_after_cursor(
                key_fn(item), item.id, cursor_value, cursor_id, descending=descending
            )
        ]

    page = ordered[: limit + 1]
    has_more = len(page) > limit
    page = page[:limit]

    next_cursor = None
    if has_more and page:
        tail = page[-1]
        next_cursor = encode_cursor(sort_key, key_fn(tail), tail.id)

    return page, total_count, next_cursor, has_more


def truthy(value: str | None) -> bool:
    if not value:
        return False
    return value.strip().lower() in {"1", "true", "yes", "on"}


def normalize_product_sort(sort: str | None) -> str:
    normalized = (sort or "latest").strip().lower()
    if normalized in {"new", "newest"}:
        return "latest"
    if normalized in {"price", "price_asc", "price_desc", "top_selling", "latest"}:
        return normalized
    return "latest"


def product_sort_config(
    sort: str,
) -> tuple[
    str,
    Literal["datetime", "decimal", "int"],
    bool,
    Callable[[Product], CursorValue],
]:
    if sort == "price_asc":
        return "price_asc", "decimal", False, lambda product: product.base_price
    if sort == "price_desc":
        return "price_desc", "decimal", True, lambda product: product.base_price
    if sort == "top_selling":
        return "top_selling", "int", True, lambda product: product.order_count_cached
    return "latest", "datetime", True, lambda product: product.created_at


def published_and_available(products: list[Product]) -> list[Product]:
    from src.models.catalog import ProductAvailabilityStatus, ProductPublishStatus

    return [
        product
        for product in products
        if product.publish_status == ProductPublishStatus.PUBLISHED
        and product.availability_status == ProductAvailabilityStatus.AVAILABLE
    ]


def match_category(product: Product, category: str) -> bool:
    category_value = category.strip().lower()
    return any(
        category_value
        in {
            str(product_category.id).lower(),
            product_category.slug.lower(),
            product_category.name.lower(),
        }
        for product_category in product.categories
    )


def product_payload(
    product: Product,
    *,
    request: Request | None = None,
    discounted_price: Decimal | None = None,
) -> ProductCardResponse:
    image_file_url = None
    if product.images:
        ordered_images = sorted(
            product.images,
            key=lambda image: (
                not image.is_primary,
                image.sort_order,
                image.created_at,
            ),
        )
        image_file_url = ordered_images[0].image_file_url

    category_names = product_category_names(product)
    tags = sorted(
        [
            product_tag.tag.name
            for product_tag in product.product_tags
            if product_tag.tag
        ],
    )
    seller_rating = format_decimal(product.seller.avg_rating)

    return ProductCardResponse(
        id=product.id,
        name=product.name,
        unit_label=product.unit_label,
        seller=ProductSellerSummaryResponse(
            id=product.seller_id, store_name=product.seller.store_name
        ),
        base_price=format_money(product.base_price),
        discounted_price=format_money(discounted_price) if discounted_price else None,
        is_on_sale=discounted_price is not None
        and discounted_price < product.base_price,
        is_low_stock=product_low_stock(product),
        image_url=product_image_url(request, image_file_url),
        categories=category_names,
        description=product.description or "",
        shelf_life_text=product.shelf_life_text or "",
        stock_status=product.stock_status.value,
        availability_status=product.availability_status.value,
        tags=tags,
        seller_rating=seller_rating,
        seller_review_count=product.seller.rating_count,
    )


def product_detail_payload(
    product: Product,
    *,
    request: Request | None = None,
    discounted_price: Decimal | None = None,
) -> ProductDetailResponse:
    return ProductDetailResponse.model_validate(
        product_payload(product, request=request, discounted_price=discounted_price)
    )


def category_payload(category) -> CategoryResponse:
    return CategoryResponse(
        id=category.id,
        name=category.name,
        slug=category.slug,
        parent_id=category.parent_id,
        display_order=category.display_order,
    )


def tag_payload(tag: Tag) -> TagResponse:
    return TagResponse(
        id=tag.id,
        name=tag.name,
        slug=tag.slug,
    )


def seller_tag_payload(row: SellerTag) -> SellerTagResponse:
    return SellerTagResponse(id=row.id, tag=tag_payload(row.tag))


def product_tag_payload(row) -> ProductTagResponse:
    return ProductTagResponse(id=row.id, tag=tag_payload(row.tag))


def campaign_item_payload(item: SaleCampaignItem) -> SaleCampaignItemSummaryResponse:
    return SaleCampaignItemSummaryResponse(
        product_id=item.product_id,
        discounted_price=format_money(item.discounted_price),
    )


def campaign_payload(campaign: SaleCampaign) -> SaleCampaignResponse:
    items = sorted(campaign.items, key=lambda item: item.created_at)
    return SaleCampaignResponse(
        id=campaign.id,
        name=campaign.name,
        campaign_type=SaleCampaignType(campaign.campaign_type.value),
        discount_percent=format_decimal(campaign.discount_percent),
        starts_at=campaign.starts_at,
        ends_at=campaign.ends_at,
        status=SaleCampaignStatus(campaign.status.value),
        items=[campaign_item_payload(item) for item in items],
    )
