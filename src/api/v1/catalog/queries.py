"""Catalog database query functions."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.shared.utils.search import build_prefix_tsquery
from src.core.exceptions import HTTPException
from src.models.catalog import (
    Category,
    Product,
    ProductAvailabilityStatus,
    ProductPublishStatus,
    ProductStockStatus,
    ProductTag,
    SaleCampaign,
    SaleCampaignItem,
    SaleCampaignStatus,
    Tag,
)
from src.models.sellers import SellerProfile


async def seller_profile_for_user(
    db: AsyncSession, user: AuthenticatedActor
) -> SellerProfile:
    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user.id)
    )
    seller_profile = result.scalar_one_or_none()
    if seller_profile is None:
        raise HTTPException(
            status_code=404,
            detail="Seller profile not found for this account.",
        )
    return seller_profile


async def load_categories(
    db: AsyncSession, category_ids: list[UUID], *, required: bool
) -> list[Category]:
    unique_category_ids = list(dict.fromkeys(category_ids))
    if not unique_category_ids:
        if required:
            raise HTTPException(
                status_code=400,
                detail={"category_ids": ["At least one category is required."]},
            )
        return []

    result = await db.execute(
        select(Category).where(
            Category.id.in_(unique_category_ids), Category.is_active.is_(True)
        )
    )
    categories_by_id = {
        category.id: category for category in list(result.scalars().all())
    }
    if len(categories_by_id) != len(unique_category_ids):
        raise HTTPException(
            status_code=400,
            detail={"category_ids": ["One or more categories were not found."]},
        )
    return [categories_by_id[category_id] for category_id in unique_category_ids]


async def visible_products(
    db: AsyncSession,
    *,
    search_query: str | None = None,
    in_stock_only: bool = False,
    min_price: Decimal | None = None,
    max_price: Decimal | None = None,
) -> list[Product]:
    statement = (
        select(Product)
        .join(SellerProfile, Product.seller_id == SellerProfile.id)
        .where(
            Product.publish_status == ProductPublishStatus.PUBLISHED,
            Product.availability_status == ProductAvailabilityStatus.AVAILABLE,
        )
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
    )

    if in_stock_only:
        statement = statement.where(
            Product.stock_status != ProductStockStatus.OUT_OF_STOCK
        )
    if min_price is not None:
        statement = statement.where(Product.base_price >= min_price)
    if max_price is not None:
        statement = statement.where(Product.base_price <= max_price)
    if search_query:
        tsquery = build_prefix_tsquery(search_query)
        if tsquery is not None:
            search_document = func.to_tsvector(
                "simple",
                func.concat_ws(
                    " ",
                    Product.name,
                    func.coalesce(Product.description, ""),
                    func.coalesce(SellerProfile.store_name, ""),
                ),
            )
            statement = statement.where(
                search_document.op("@@")(func.to_tsquery("simple", tsquery))
            )

    result = await db.execute(statement)
    return list(result.scalars().unique().all())


async def seller_products(db: AsyncSession, seller_id: UUID) -> list[Product]:
    result = await db.execute(
        select(Product)
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(Product.seller_id == seller_id)
    )
    return list(result.scalars().all())


async def sale_price_map(
    db: AsyncSession, product_ids: set[UUID]
) -> dict[UUID, Decimal]:
    if not product_ids:
        return {}

    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(SaleCampaignItem)
        .join(SaleCampaign, SaleCampaignItem.campaign_id == SaleCampaign.id)
        .where(
            SaleCampaignItem.product_id.in_(product_ids),
            SaleCampaign.status == SaleCampaignStatus.ACTIVE,
            SaleCampaign.starts_at <= now,
            SaleCampaign.ends_at >= now,
        )
        .order_by(SaleCampaignItem.product_id, SaleCampaignItem.discounted_price)
    )

    sale_prices: dict[UUID, Decimal] = {}
    for item in list(result.scalars().all()):
        sale_prices.setdefault(item.product_id, item.discounted_price)
    return sale_prices


async def validate_allowed_tags(
    db: AsyncSession,
    tag_ids: list[UUID],
) -> dict[UUID, Tag]:
    unique_tag_ids = list(dict.fromkeys(tag_ids))
    if not unique_tag_ids:
        return {}

    result = await db.execute(
        select(Tag).where(
            Tag.id.in_(unique_tag_ids),
            Tag.is_active.is_(True),
        )
    )
    tags = {tag.id: tag for tag in list(result.scalars().all())}
    if len(tags) != len(unique_tag_ids):
        raise HTTPException(
            status_code=400,
            detail="One or more tags are invalid or inactive.",
        )
    return tags


async def sync_stock_status(
    product: Product, *, preserve_existing: bool = False
) -> None:
    if product.stock_quantity <= 0:
        product.stock_status = ProductStockStatus.OUT_OF_STOCK
    elif preserve_existing:
        return
    elif product.stock_quantity <= product.low_stock_threshold:
        product.stock_status = ProductStockStatus.LOW_STOCK
    elif product.stock_status in {
        ProductStockStatus.LOW_STOCK,
        ProductStockStatus.OUT_OF_STOCK,
    }:
        product.stock_status = ProductStockStatus.IN_STOCK


async def generate_product_slug(
    db: AsyncSession,
    *,
    seller_id: UUID,
    name: str,
    product_id: UUID | None = None,
) -> str:
    from src.api.v1.catalog.utils import normalize_slug

    base = normalize_slug(name)
    candidate = base
    counter = 2

    while True:
        query = select(Product.id).where(
            Product.seller_id == seller_id, Product.slug == candidate
        )
        if product_id is not None:
            query = query.where(Product.id != product_id)
        result = await db.execute(query.limit(1))
        if result.scalar_one_or_none() is None:
            return candidate
        candidate = f"{base}-{counter}"
        counter += 1


async def ensure_active_sale(
    db: AsyncSession,
    *,
    product: Product,
    discounted_price: Decimal,
    seller: SellerProfile,
) -> None:
    from src.api.v1.catalog.schema import SaleCampaignType

    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(SaleCampaign)
        .where(
            SaleCampaign.seller_id == seller.id,
            SaleCampaign.status == SaleCampaignStatus.ACTIVE,
            SaleCampaign.starts_at <= now,
            SaleCampaign.ends_at >= now,
        )
        .order_by(SaleCampaign.starts_at)
        .limit(1)
    )
    campaign = result.scalar_one_or_none()
    if campaign is None:
        campaign = SaleCampaign(
            seller_id=seller.id,
            name="Instant product promo",
            campaign_type=SaleCampaignType.SINGLE_ITEM,
            discount_percent=Decimal("0.01"),
            starts_at=now,
            ends_at=now + timedelta(days=30),
            status=SaleCampaignStatus.ACTIVE,
        )
        db.add(campaign)
        await db.flush()

    result = await db.execute(
        select(SaleCampaignItem).where(
            SaleCampaignItem.campaign_id == campaign.id,
            SaleCampaignItem.product_id == product.id,
        )
    )
    item = result.scalar_one_or_none()
    if item is None:
        db.add(
            SaleCampaignItem(
                campaign_id=campaign.id,
                product_id=product.id,
                original_price_snapshot=product.base_price,
                discounted_price=discounted_price,
            )
        )
    else:
        item.original_price_snapshot = product.base_price
        item.discounted_price = discounted_price


async def remove_active_sale(
    db: AsyncSession, *, product: Product, seller: SellerProfile
) -> None:
    now = datetime.now(timezone.utc)
    await db.execute(
        delete(SaleCampaignItem)
        .where(
            SaleCampaignItem.product_id == product.id,
        )
        .where(
            SaleCampaignItem.campaign_id.in_(
                select(SaleCampaign.id).where(
                    SaleCampaign.seller_id == seller.id,
                    SaleCampaign.status == SaleCampaignStatus.ACTIVE,
                    SaleCampaign.starts_at <= now,
                    SaleCampaign.ends_at >= now,
                )
            )
        )
    )


async def sync_seller_catalog_counters(db: AsyncSession, seller: SellerProfile) -> None:
    from src.models.catalog import Product

    total_items_result = await db.execute(
        select(func.count(Product.id)).where(
            Product.seller_id == seller.id,
            Product.publish_status == ProductPublishStatus.PUBLISHED,
        )
    )
    total_items_count = int(total_items_result.scalar_one())

    now = datetime.now(timezone.utc)
    sale_items_result = await db.execute(
        select(func.count(func.distinct(SaleCampaignItem.product_id)))
        .join(SaleCampaign, SaleCampaignItem.campaign_id == SaleCampaign.id)
        .join(Product, SaleCampaignItem.product_id == Product.id)
        .where(
            SaleCampaign.seller_id == seller.id,
            SaleCampaign.status == SaleCampaignStatus.ACTIVE,
            SaleCampaign.starts_at <= now,
            SaleCampaign.ends_at >= now,
            Product.publish_status == ProductPublishStatus.PUBLISHED,
        )
    )
    items_on_sale_count = int(sale_items_result.scalar_one())

    if (
        seller.total_items_count != total_items_count
        or seller.items_on_sale_count != items_on_sale_count
    ):
        seller.total_items_count = total_items_count
        seller.items_on_sale_count = items_on_sale_count


async def product_owned_by_seller(
    db: AsyncSession, product_id: UUID, seller_id: UUID
) -> Product:
    result = await db.execute(
        select(Product)
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(Product.id == product_id, Product.seller_id == seller_id)
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(
            status_code=404,
            detail="Product not found.",
        )
    return product
