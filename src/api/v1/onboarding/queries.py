import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models.auth import Address


async def get_default_address(db: AsyncSession, user_id: uuid.UUID) -> Address | None:
    """Fetch user's default address."""
    result = await db.execute(
        select(Address).where(Address.user_id == user_id, Address.is_default.is_(True))
    )
    return result.scalar_one_or_none()
