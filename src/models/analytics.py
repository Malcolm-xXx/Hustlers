"""
Analytics models for tracking daily metrics.

These models store daily aggregations that serve as the authoritative source
for various cached fields on SellerProfile and Product. Any cached fields
should be computed from these daily metrics rather than maintained independently.
"""

import uuid
from datetime import datetime, date
from decimal import Decimal

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from src.core.database import Base


class ListingViewEvent(Base):
    __tablename__ = "listing_view_events"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    viewer_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    seller_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=True
    )
    product_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("products.id"), nullable=True
    )
    source_screen: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    __table_args__ = (
        Index("idx_lve_seller_created", "seller_id", "created_at"),
        Index("idx_lve_product_created", "product_id", "created_at"),
        Index("idx_lve_viewer_created", "viewer_user_id", "created_at"),
    )


class SellerDailyMetric(Base):
    __tablename__ = "seller_daily_metrics"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    metric_date: Mapped[date] = mapped_column(Date, nullable=False)
    orders_count: Mapped[int] = mapped_column(Integer, default=0)
    completed_orders_count: Mapped[int] = mapped_column(Integer, default=0)
    earnings_amount: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0")
    )
    views_count: Mapped[int] = mapped_column(Integer, default=0)
    avg_rating: Mapped[Decimal] = mapped_column(Numeric(3, 2), default=Decimal("0"))
    avg_delivery_minutes: Mapped[int] = mapped_column(Integer, default=0)
    success_rate: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("0"))

    __table_args__ = (
        UniqueConstraint(
            "seller_id", "metric_date", name="uq_seller_daily_metrics_seller_date"
        ),
        Index("idx_seller_daily_metrics_date", "metric_date"),
    )


class ProductDailyMetric(Base):
    __tablename__ = "product_daily_metrics"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id"), nullable=False
    )
    metric_date: Mapped[date] = mapped_column(Date, nullable=False)
    views_count: Mapped[int] = mapped_column(Integer, default=0)
    orders_count: Mapped[int] = mapped_column(Integer, default=0)
    gross_sales_amount: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0")
    )

    __table_args__ = (
        UniqueConstraint(
            "product_id", "metric_date", name="uq_product_daily_metrics_product_date"
        ),
        Index("idx_product_daily_metrics_date", "metric_date"),
    )


class LocationDailyMetric(Base):
    __tablename__ = "location_daily_metrics"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    location_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("service_area_locations.id"), nullable=False
    )
    metric_date: Mapped[date] = mapped_column(Date, nullable=False)
    orders_count: Mapped[int] = mapped_column(Integer, default=0)
    buyers_count: Mapped[int] = mapped_column(Integer, default=0)
    sellers_count: Mapped[int] = mapped_column(Integer, default=0)
    avg_order_amount: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0")
    )

    __table_args__ = (
        UniqueConstraint(
            "location_id", "metric_date", name="uq_location_daily_metrics_location_date"
        ),
        Index("idx_location_daily_metrics_date", "metric_date"),
    )
