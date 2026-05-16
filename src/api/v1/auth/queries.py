import uuid

from fastapi import status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.exceptions import HTTPException
from src.models.auth import (
    Address,
    EmailVerificationOTP,
    PasswordResetOTP,
    User,
)


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    """Fetch user by email address."""
    result = await db.execute(select(User).where(User.email == email.lower()))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    """Fetch user by ID."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_email_verification_otp(
    db: AsyncSession, user: User
) -> EmailVerificationOTP | None:
    """Fetch active email verification OTP for user."""
    result = await db.execute(
        select(EmailVerificationOTP).where(EmailVerificationOTP.user_id == user.id)
    )
    return result.scalar_one_or_none()


async def get_password_reset_otp(
    db: AsyncSession, user: User
) -> PasswordResetOTP | None:
    """Fetch active password reset OTP for user."""
    result = await db.execute(
        select(PasswordResetOTP).where(PasswordResetOTP.user_id == user.id)
    )
    return result.scalar_one_or_none()


async def unset_default_addresses(db: AsyncSession, user: User) -> None:
    """Unset all default addresses for a user."""
    await db.execute(
        update(Address)
        .where(Address.user_id == user.id, Address.is_default.is_(True))
        .values(is_default=False)
        .execution_options(synchronize_session=False)
    )


async def get_addresses_by_user(db: AsyncSession, user: User) -> list[Address]:
    """Fetch addresses for a user ordered by creation time."""
    result = await db.execute(
        select(Address)
        .where(Address.user_id == user.id)
        .order_by(Address.created_at.asc())
    )
    return list(result.scalars().all())


async def get_address_by_id(db: AsyncSession, address_id: uuid.UUID) -> Address | None:
    """Fetch an address by ID."""
    result = await db.execute(select(Address).where(Address.id == address_id))
    return result.scalar_one_or_none()


async def get_address_or_404(
    db: AsyncSession, user: User, address_id: uuid.UUID
) -> Address:
    """Fetch an address and verify ownership, or raise 404."""
    address = await get_address_by_id(db, address_id)
    if not address:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Address not found")
    if address.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Address not found")
    return address
