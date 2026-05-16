from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.discovery import FavoriteProduct, FavoriteSeller
    from src.models.marketplace import HustleList
    from src.models.messaging import ConversationMember, Message
    from src.models.notifications import DeviceRegistration, Notification
    from src.models.sellers import SellerProfile
    from src.models.carts import Cart


class UserRole(enum.Enum):
    BUYER = "buyer"
    SELLER = "seller"
    ADMIN = "admin"


class UserAccountStatus(enum.Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    BANNED = "banned"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    profile_photo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    profile_photo_cloudinary_public_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, native_enum=False), default=UserRole.BUYER
    )
    is_email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_onboarded: Mapped[bool] = mapped_column(Boolean, default=False)
    onboarding_data: Mapped[dict] = mapped_column(JSONB, default=dict)
    account_status: Mapped[UserAccountStatus] = mapped_column(
        Enum(UserAccountStatus, native_enum=False),
        default=UserAccountStatus.ACTIVE,
        nullable=False,
    )
    suspended_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    suspension_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    ban_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    google_uid: Mapped[str | None] = mapped_column(
        String(255), unique=True, nullable=True
    )
    is_staff: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    addresses: Mapped[list["Address"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    favorite_sellers: Mapped[list["FavoriteSeller"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    favorite_products: Mapped[list["FavoriteProduct"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    notifications: Mapped[list["Notification"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    device_registrations: Mapped[list["DeviceRegistration"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    conversation_memberships: Mapped[list["ConversationMember"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    messages_sent: Mapped[list["Message"]] = relationship(
        back_populates="sender_user", cascade="all, delete-orphan"
    )
    seller_profile: Mapped["SellerProfile | None"] = relationship(
        back_populates="user", uselist=False
    )
    password_reset_otp: Mapped["PasswordResetOTP | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    email_verification_otp: Mapped["EmailVerificationOTP | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    carts: Mapped[list["Cart"]] = relationship(
        back_populates="buyer", cascade="all, delete-orphan"
    )

    refresh_tokens: Mapped[list["RefreshTokenBlacklist"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class TokenType(enum.Enum):
    ACCESS = "access"
    REFRESH = "refresh"


class RefreshTokenBlacklist(Base):
    __tablename__ = "refresh_token_blacklist"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    jti: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    token_type: Mapped[TokenType] = mapped_column(
        Enum(TokenType, native_enum=False), nullable=False
    )
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    blacklisted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="refresh_tokens")


class Address(Base):
    __tablename__ = "addresses"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address_text: Mapped[str] = mapped_column(Text, default="")
    latitude: Mapped[float] = mapped_column(nullable=False)
    longitude: Mapped[float] = mapped_column(nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="addresses")
    hustle_lists: Mapped[list["HustleList"]] = relationship(
        back_populates="delivery_address"
    )

    __table_args__ = (
        Index(
            "uq_one_default_address_per_user",
            "user_id",
            unique=True,
            postgresql_where=text("is_default"),
        ),
    )


class PasswordResetOTP(Base):
    __tablename__ = "password_reset_otps"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=False
    )
    code: Mapped[str] = mapped_column(String(6), nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_token: Mapped[str | None] = mapped_column(String(128), nullable=True)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="password_reset_otp")


class EmailVerificationOTP(Base):
    __tablename__ = "email_verification_otps"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=False
    )
    code: Mapped[str] = mapped_column(String(6), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="email_verification_otp")
