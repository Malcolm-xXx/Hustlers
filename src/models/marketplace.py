from __future__ import annotations

import enum
import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.auth import Address
    from src.models.sellers import SellerPresence, SellerProfile, SellerServiceArea


class ServiceAreaLocationProvider(enum.Enum):
    GOOGLE_PLACES = "google_places"
    GEOAPIFY = "geoapify"


class HustleListStatus(enum.Enum):
    DRAFT = "draft"
    OPEN = "open"
    ACCEPTED = "accepted"
    CONVERTED = "converted"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class HustleListDispatchChannel(enum.Enum):
    DIRECT = "direct"
    MARKETPLACE = "marketplace"


class HustleListDispatchStatus(enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    BUYER_APPROVAL_PENDING = "buyer_approval_pending"
    DECLINED = "declined"
    EXPIRED = "expired"
    WITHDRAWN = "withdrawn"


class ServiceAreaLocation(Base):
    __tablename__ = "service_area_locations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    provider: Mapped[ServiceAreaLocationProvider] = mapped_column(
        Enum(ServiceAreaLocationProvider, native_enum=False),
        default=ServiceAreaLocationProvider.GOOGLE_PLACES,
    )
    provider_place_id: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address_text: Mapped[str] = mapped_column(String(500), nullable=False)
    latitude: Mapped[float] = mapped_column(Numeric(9, 6), nullable=False)
    longitude: Mapped[float] = mapped_column(Numeric(9, 6), nullable=False)
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    service_areas: Mapped[list["SellerServiceArea"]] = relationship(
        back_populates="location"
    )
    seller_presences: Mapped[list["SellerPresence"]] = relationship(
        back_populates="current_location"
    )
    hustle_lists: Mapped[list["HustleList"]] = relationship(
        back_populates="shopping_location"
    )

    __table_args__ = (
        UniqueConstraint(
            "provider",
            "provider_place_id",
            name="uq_service_area_locations_provider_place_id",
        ),
    )


class HustleList(Base):
    __tablename__ = "hustle_lists"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    buyer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[HustleListStatus] = mapped_column(
        Enum(HustleListStatus, native_enum=False), default=HustleListStatus.DRAFT
    )
    shopping_location_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("service_area_locations.id"), nullable=True
    )
    delivery_address_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("addresses.id", ondelete="SET NULL"), nullable=True
    )
    delivery_fee: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))
    delivery_window_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    delivery_window_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    delivery_window_label: Mapped[str] = mapped_column(String(120), default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    items: Mapped[list["HustleListItem"]] = relationship(
        back_populates="hustle_list", cascade="all, delete-orphan"
    )
    dispatches: Mapped[list["HustleListDispatch"]] = relationship(
        back_populates="hustle_list", cascade="all, delete-orphan"
    )
    delivery_address: Mapped["Address"] = relationship(back_populates="hustle_lists")
    shopping_location: Mapped["ServiceAreaLocation | None"] = relationship(
        back_populates="hustle_lists"
    )


class HustleListItem(Base):
    __tablename__ = "hustle_list_items"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    hustle_list_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("hustle_lists.id"), nullable=False
    )
    requested_name: Mapped[str] = mapped_column(String(255), nullable=False)
    quantity_value: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), default=Decimal("1")
    )
    unit_label: Mapped[str] = mapped_column(String(50), default="")
    target_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    note: Mapped[str] = mapped_column(Text, default="")
    sort_order: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    hustle_list: Mapped["HustleList"] = relationship(back_populates="items")


class HustleListDispatch(Base):
    __tablename__ = "hustle_list_dispatches"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    hustle_list_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("hustle_lists.id"), nullable=False
    )
    channel: Mapped[HustleListDispatchChannel] = mapped_column(
        Enum(HustleListDispatchChannel, native_enum=False), nullable=False
    )
    target_seller_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=True
    )
    accepted_by_seller_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=True
    )
    buyer_approved_seller_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=True
    )
    status: Mapped[HustleListDispatchStatus] = mapped_column(
        Enum(HustleListDispatchStatus, native_enum=False),
        default=HustleListDispatchStatus.PENDING,
    )
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    hustle_list: Mapped["HustleList"] = relationship(back_populates="dispatches")
    target_seller: Mapped["SellerProfile | None"] = relationship(
        "SellerProfile",
        foreign_keys=[target_seller_id],
        back_populates="targeted_dispatches",
        lazy="selectin",
    )
    accepted_by_seller: Mapped["SellerProfile | None"] = relationship(
        "SellerProfile",
        foreign_keys=[accepted_by_seller_id],
        back_populates="accepted_dispatches",
        lazy="selectin",
    )
    buyer_approved_seller: Mapped["SellerProfile | None"] = relationship(
        "SellerProfile",
        foreign_keys=[buyer_approved_seller_id],
    )

    __table_args__ = (
        CheckConstraint(
            """
            (
                channel = 'marketplace' AND buyer_approved_seller_id IS NOT NULL
            ) OR (
                channel = 'direct'
            )
            """,
            name="chk_dispatch_buyer_approval",
        ),
    )
