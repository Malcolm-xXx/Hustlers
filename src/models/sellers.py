from __future__ import annotations

import enum
import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from src.core.database import Base

if TYPE_CHECKING:
    from src.models.catalog import Product, SaleCampaign, SellerTag
    from src.models.auth import User
    from src.models.discovery import FavoriteSeller
    from src.models.marketplace import HustleListDispatch, ServiceAreaLocation


class SellerPresenceStatus(enum.Enum):
    OFFLINE = "offline"
    ACTIVE = "active"
    AT_MARKET = "at_market"
    BUSY = "busy"


class SellerProfile(Base):
    __tablename__ = "seller_profiles"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=False
    )
    store_name: Mapped[str] = mapped_column(String(255), default="")
    bio: Mapped[str] = mapped_column(Text, default="")
    profile_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    profile_image_cloudinary_public_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    banner_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    banner_image_cloudinary_public_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    is_accepting_orders: Mapped[bool] = mapped_column(Boolean, default=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    # Cache. Source of truth: OrderReview (aggregated) via SellerDailyMetric
    avg_rating: Mapped[Decimal] = mapped_column(Numeric(3, 2), default=Decimal("0"))
    # Cache. Source of truth: OrderReview (count of submitted reviews)
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: Order (status=DONE)
    completed_orders_count: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: Order (status in ACCEPTED/SHOPPING/DELIVERING)
    active_orders_count: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: Product (publish_status=PUBLISHED)
    total_items_count: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: SaleCampaignItem (via active SaleCampaign)
    items_on_sale_count: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: ListingViewEvent (rolling 7-day window)
    weekly_store_views: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: SellerDailyMetric
    average_delivery_minutes: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: SellerDailyMetric
    success_rate: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("0"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship(back_populates="seller_profile")

    service_areas: Mapped[list["SellerServiceArea"]] = relationship(
        back_populates="seller", cascade="all, delete-orphan"
    )
    presence: Mapped["SellerPresence | None"] = relationship(
        back_populates="seller", uselist=False, cascade="all, delete-orphan"
    )
    products: Mapped[list["Product"]] = relationship(back_populates="seller")
    seller_tags: Mapped[list["SellerTag"]] = relationship(
        back_populates="seller", cascade="all, delete-orphan"
    )
    sale_campaigns: Mapped[list["SaleCampaign"]] = relationship(
        back_populates="seller", cascade="all, delete-orphan"
    )
    favorited_by: Mapped[list["FavoriteSeller"]] = relationship(
        back_populates="seller", cascade="all, delete-orphan"
    )
    targeted_dispatches: Mapped[list["HustleListDispatch"]] = relationship(
        "HustleListDispatch",
        foreign_keys="[HustleListDispatch.target_seller_id]",
        back_populates="target_seller",
    )
    accepted_dispatches: Mapped[list["HustleListDispatch"]] = relationship(
        "HustleListDispatch",
        foreign_keys="[HustleListDispatch.accepted_by_seller_id]",
        back_populates="accepted_by_seller",
    )


class SellerServiceArea(Base):
    __tablename__ = "seller_service_areas"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    location_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_area_locations.id"), nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    seller: Mapped["SellerProfile"] = relationship(back_populates="service_areas")
    location: Mapped["ServiceAreaLocation"] = relationship(
        back_populates="service_areas"
    )

    __table_args__ = (
        UniqueConstraint(
            "seller_id", "location_id", name="uq_seller_service_areas_seller_loc"
        ),
    )


class SellerPresence(Base):
    __tablename__ = "seller_presence"

    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), primary_key=True
    )
    status: Mapped[SellerPresenceStatus] = mapped_column(
        Enum(SellerPresenceStatus, native_enum=False),
        default=SellerPresenceStatus.OFFLINE,
    )
    current_location_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("service_area_locations.id"), nullable=True
    )
    last_seen_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    seller: Mapped["SellerProfile"] = relationship(back_populates="presence")
    current_location: Mapped["ServiceAreaLocation | None"] = relationship(
        back_populates="seller_presences"
    )
