import uuid

from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.exceptions import HTTPException
from src.models.auth import User
from src.models.catalog import SellerTag
from src.models.sellers import (
    SellerPresence,
    SellerProfile,
    SellerServiceArea,
)


async def get_seller_profile_by_id(
    db: AsyncSession,
    seller_id: uuid.UUID,
) -> SellerProfile | None:
    """Fetch a seller profile by seller ID."""
    statement = (
        select(SellerProfile)
        .options(
            selectinload(SellerProfile.presence).selectinload(
                SellerPresence.current_location
            ),
            selectinload(SellerProfile.service_areas).selectinload(
                SellerServiceArea.location
            ),
            selectinload(SellerProfile.seller_tags).selectinload(SellerTag.tag),
        )
        .where(SellerProfile.id == seller_id)
        .where(SellerProfile.is_deleted.is_(False))
    )
    result = await db.execute(statement.limit(1))
    return result.scalar_one_or_none()


async def get_seller_profile_by_user_id(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> SellerProfile | None:
    """Fetch a seller profile by user ID."""
    statement = (
        select(SellerProfile)
        .options(
            selectinload(SellerProfile.presence).selectinload(
                SellerPresence.current_location
            ),
            selectinload(SellerProfile.service_areas).selectinload(
                SellerServiceArea.location
            ),
            selectinload(SellerProfile.seller_tags).selectinload(SellerTag.tag),
        )
        .where(SellerProfile.user_id == user_id)
        .where(SellerProfile.is_deleted.is_(False))
    )
    result = await db.execute(statement.limit(1))
    return result.scalar_one_or_none()


async def load_seller_profile(
    db: AsyncSession,
    *,
    seller_id: uuid.UUID | None = None,
    user_id: uuid.UUID | None = None,
    missing_detail: str,
) -> SellerProfile:
    """Load a seller profile by seller_id or user_id."""
    if seller_id is not None:
        seller = await get_seller_profile_by_id(db, seller_id)
    elif user_id is not None:
        seller = await get_seller_profile_by_user_id(db, user_id)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either seller_id or user_id must be provided.",
        )

    if seller is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=missing_detail,
        )
    return seller


async def get_sellers_by_ids(
    db: AsyncSession,
    seller_ids: set[uuid.UUID],
) -> dict[uuid.UUID, SellerProfile]:
    """Fetch multiple seller profiles by their IDs."""
    if not seller_ids:
        return {}

    statement = (
        select(SellerProfile)
        .options(
            selectinload(SellerProfile.presence).selectinload(
                SellerPresence.current_location
            ),
            selectinload(SellerProfile.seller_tags).selectinload(SellerTag.tag),
        )
        .where(SellerProfile.id.in_(seller_ids))
        .where(SellerProfile.is_deleted.is_(False))
    )
    result = await db.execute(statement)
    return {seller.id: seller for seller in result.scalars().all()}


async def get_users_by_ids(
    db: AsyncSession,
    user_ids: set[uuid.UUID],
) -> dict[uuid.UUID, User]:
    """Fetch multiple users by their IDs."""
    if not user_ids:
        return {}

    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    return {user.id: user for user in result.scalars().all()}
