from __future__ import annotations

import uuid

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.models.auth import Address, User, UserAccountStatus
from src.models.catalog import (
    Category,
    Product,
    ProductAvailabilityStatus,
    ProductPublishStatus,
    SaleCampaignItem,
    SellerTag,
)
from src.models.discovery import FavoriteProduct, FavoriteSeller
from src.models.marketplace import ServiceAreaLocation
from src.models.sellers import SellerProfile


async def get_favorite_seller_ids(
    db: AsyncSession, user_id: uuid.UUID
) -> set[uuid.UUID]:
    result = await db.execute(
        select(FavoriteSeller.seller_id).where(FavoriteSeller.user_id == user_id)
    )
    return set(result.scalars().all())


async def get_favorite_product_ids(
    db: AsyncSession, user_id: uuid.UUID
) -> set[uuid.UUID]:
    result = await db.execute(
        select(FavoriteProduct.product_id).where(FavoriteProduct.user_id == user_id)
    )
    return set(result.scalars().all())


async def get_favorite_seller_links(
    db: AsyncSession, user_id: uuid.UUID
) -> list[FavoriteSeller]:
    result = await db.execute(
        select(FavoriteSeller)
        .where(FavoriteSeller.user_id == user_id)
        .order_by(desc(FavoriteSeller.created_at), desc(FavoriteSeller.id))
    )
    return list(result.scalars().all())


async def get_favorite_product_links(
    db: AsyncSession, user_id: uuid.UUID
) -> list[FavoriteProduct]:
    result = await db.execute(
        select(FavoriteProduct)
        .where(FavoriteProduct.user_id == user_id)
        .order_by(desc(FavoriteProduct.created_at), desc(FavoriteProduct.id))
    )
    return list(result.scalars().all())


async def get_existing_favorite_seller(
    db: AsyncSession,
    user_id: uuid.UUID,
    seller_id: uuid.UUID,
) -> FavoriteSeller | None:
    result = await db.execute(
        select(FavoriteSeller)
        .where(FavoriteSeller.user_id == user_id, FavoriteSeller.seller_id == seller_id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_existing_favorite_product(
    db: AsyncSession,
    user_id: uuid.UUID,
    product_id: uuid.UUID,
) -> FavoriteProduct | None:
    result = await db.execute(
        select(FavoriteProduct)
        .where(
            FavoriteProduct.user_id == user_id,
            FavoriteProduct.product_id == product_id,
        )
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_seller_profile_for_favorite(
    db: AsyncSession,
    seller_id: uuid.UUID,
) -> SellerProfile | None:
    result = await db.execute(
        select(SellerProfile)
        .join(User, SellerProfile.user_id == User.id)
        .options(
            selectinload(SellerProfile.user),
            selectinload(SellerProfile.presence),
            selectinload(SellerProfile.seller_tags).selectinload(SellerTag.tag),
        )
        .where(
            SellerProfile.id == seller_id,
            SellerProfile.is_deleted.is_(False),
            User.account_status == UserAccountStatus.ACTIVE,
        )
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_product_for_favorite(
    db: AsyncSession,
    product_id: uuid.UUID,
) -> Product | None:
    result = await db.execute(
        select(Product)
        .join(SellerProfile, Product.seller_id == SellerProfile.id)
        .join(User, SellerProfile.user_id == User.id)
        .options(
            selectinload(Product.seller).selectinload(SellerProfile.presence),
            selectinload(Product.categories).selectinload(Category.parent),
            selectinload(Product.images),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(
            Product.id == product_id,
            User.account_status == UserAccountStatus.ACTIVE,
            SellerProfile.is_deleted.is_(False),
            Product.publish_status == ProductPublishStatus.PUBLISHED,
            Product.availability_status == ProductAvailabilityStatus.AVAILABLE,
        )
        .limit(1)
    )
    return result.scalar_one_or_none()


async def load_seller_profiles(db: AsyncSession) -> list[SellerProfile]:
    result = await db.execute(
        select(SellerProfile)
        .join(User, SellerProfile.user_id == User.id)
        .options(
            selectinload(SellerProfile.user),
            selectinload(SellerProfile.presence),
            selectinload(SellerProfile.seller_tags).selectinload(SellerTag.tag),
        )
        .where(
            User.account_status == UserAccountStatus.ACTIVE,
            SellerProfile.is_deleted.is_(False),
        )
    )
    return list(result.scalars().unique().all())


async def load_products(db: AsyncSession) -> list[Product]:
    result = await db.execute(
        select(Product)
        .join(SellerProfile, Product.seller_id == SellerProfile.id)
        .join(User, SellerProfile.user_id == User.id)
        .options(
            selectinload(Product.seller).selectinload(SellerProfile.presence),
            selectinload(Product.categories).selectinload(Category.parent),
            selectinload(Product.images),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(
            User.account_status == UserAccountStatus.ACTIVE,
            SellerProfile.is_deleted.is_(False),
            Product.publish_status == ProductPublishStatus.PUBLISHED,
            Product.availability_status == ProductAvailabilityStatus.AVAILABLE,
        )
    )
    return list(result.scalars().unique().all())


async def load_locations(db: AsyncSession) -> list[ServiceAreaLocation]:
    result = await db.execute(
        select(ServiceAreaLocation).where(ServiceAreaLocation.is_active.is_(True))
    )
    return list(result.scalars().all())


async def resolve_origin_coordinates(
    db: AsyncSession,
    user_id: uuid.UUID,
    address_id: uuid.UUID | None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> tuple[Address | None, tuple[float, float] | None]:
    if latitude is not None and longitude is not None:
        return None, (latitude, longitude)

    selected_address: Address | None = None

    if address_id is not None:
        selected_result = await db.execute(
            select(Address)
            .where(Address.user_id == user_id, Address.id == address_id)
            .limit(1)
        )
        selected_address = selected_result.scalar_one_or_none()

    if selected_address is None:
        default_result = await db.execute(
            select(Address)
            .where(Address.user_id == user_id, Address.is_default.is_(True))
            .order_by(desc(Address.created_at))
            .limit(1)
        )
        selected_address = default_result.scalar_one_or_none()

    if selected_address is None:
        latest_result = await db.execute(
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(desc(Address.created_at))
            .limit(1)
        )
        selected_address = latest_result.scalar_one_or_none()

    if selected_address is None:
        return None, None

    return selected_address, (
        float(selected_address.latitude),
        float(selected_address.longitude),
    )


async def load_locations_by_ids(
    db: AsyncSession,
    location_ids: set[uuid.UUID],
) -> dict[uuid.UUID, ServiceAreaLocation]:
    if not location_ids:
        return {}

    result = await db.execute(
        select(ServiceAreaLocation).where(ServiceAreaLocation.id.in_(location_ids))
    )
    return {location.id: location for location in result.scalars().all()}
