import enum
import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.auth import User
    from src.models.sellers import SellerProfile


class OrderSourceType(enum.Enum):
    CATALOG_CHECKOUT = "catalog_checkout"
    HUSTLE_LIST = "hustle_list"


class OrderStatus(enum.Enum):
    PENDING_PAYMENT = "pending_payment"
    ACCEPTED = "accepted"
    SHOPPING = "shopping"
    DELIVERING = "delivering"
    REVIEWING = "reviewing"
    DONE = "done"
    CANCELLED = "cancelled"
    DISPUTED = "disputed"


class OrderItemFulfillmentStatus(enum.Enum):
    PENDING = "pending"
    BOUGHT = "bought"
    SUBSTITUTED = "substituted"
    CANCELLED = "cancelled"
    DELIVERED = "delivered"


class OrderItemAdjustmentStatus(enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"


class OrderItemAlternativeStatus(enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"


class OrderComplaintStatus(enum.Enum):
    PENDING = "pending"
    REVIEWING = "reviewing"
    REVIEWED = "reviewed"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_number: Mapped[str] = mapped_column(String(32), unique=True, nullable=False)
    buyer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    source_type: Mapped[OrderSourceType] = mapped_column(
        Enum(OrderSourceType, native_enum=False), nullable=False
    )
    source_cart_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("carts.id"), nullable=True
    )
    source_hustle_list_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hustle_lists.id"), nullable=True
    )
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, native_enum=False), default=OrderStatus.PENDING_PAYMENT
    )
    pickup_location_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("service_area_locations.id"), nullable=True
    )
    delivery_address_snapshot_json: Mapped[dict] = mapped_column(JSON, default=dict)
    subtotal_amount: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0")
    )
    delivery_fee_amount: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0")
    )
    service_fee_amount: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0")
    )
    seller_eta_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    special_instructions: Mapped[str] = mapped_column(Text, default="")
    seller_marked_delivered_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    buyer_confirmed_delivered_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan"
    )
    status_events: Mapped[list["OrderStatusEvent"]] = relationship(
        back_populates="order", cascade="all, delete-orphan"
    )
    review: Mapped["OrderReview | None"] = relationship(
        back_populates="order", uselist=False, cascade="all, delete-orphan"
    )
    complaint: Mapped["OrderComplaint | None"] = relationship(
        back_populates="order", uselist=False, cascade="all, delete-orphan"
    )
    buyer: Mapped["User"] = relationship(
        foreign_keys=[buyer_id], back_populates="orders"
    )
    seller: Mapped["SellerProfile"] = relationship(
        foreign_keys=[seller_id], back_populates="orders"
    )

    __table_args__ = (
        CheckConstraint(
            """
            (
                source_type = 'catalog_checkout'
                AND source_cart_id IS NOT NULL
                AND source_hustle_list_id IS NULL
            ) OR (
                source_type = 'hustle_list'
                AND source_hustle_list_id IS NOT NULL
                AND source_cart_id IS NULL
            )
            """,
            name="chk_order_source_consistency",
        ),
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), nullable=False)
    product_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("products.id"), nullable=True
    )
    source_hustle_list_item_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hustle_list_items.id"), nullable=True
    )
    display_name: Mapped[str] = mapped_column(String(255), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    unit_label: Mapped[str] = mapped_column(String(50), nullable=False)
    base_unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    final_unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    line_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    fulfillment_status: Mapped[OrderItemFulfillmentStatus] = mapped_column(
        Enum(OrderItemFulfillmentStatus, native_enum=False),
        default=OrderItemFulfillmentStatus.PENDING,
    )
    note: Mapped[str] = mapped_column(Text, default="")
    image_snapshot: Mapped[str] = mapped_column(String(500), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    order: Mapped["Order"] = relationship(back_populates="items")
    adjustments: Mapped[list["OrderItemAdjustment"]] = relationship(
        back_populates="order_item", cascade="all, delete-orphan"
    )
    alternatives: Mapped[list["OrderItemAlternative"]] = relationship(
        back_populates="order_item", cascade="all, delete-orphan"
    )


class OrderStatusEvent(Base):
    __tablename__ = "order_status_events"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), nullable=False)
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, native_enum=False), nullable=False
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    order: Mapped["Order"] = relationship(back_populates="status_events")


class OrderItemAdjustment(Base):
    __tablename__ = "order_item_adjustments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("order_items.id"), nullable=False
    )
    proposed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    old_unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    new_unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    reason: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[OrderItemAdjustmentStatus] = mapped_column(
        Enum(OrderItemAdjustmentStatus, native_enum=False),
        default=OrderItemAdjustmentStatus.PENDING,
    )
    reviewed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    order_item: Mapped["OrderItem"] = relationship(back_populates="adjustments")


class OrderItemAlternative(Base):
    __tablename__ = "order_item_alternatives"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("order_items.id"), nullable=False
    )
    suggested_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    suggested_product_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("products.id"), nullable=True
    )
    suggested_name: Mapped[str] = mapped_column(String(255), default="")
    suggested_unit_label: Mapped[str] = mapped_column(String(50), default="")
    suggested_price: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2), nullable=True
    )
    note: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[OrderItemAlternativeStatus] = mapped_column(
        Enum(OrderItemAlternativeStatus, native_enum=False),
        default=OrderItemAlternativeStatus.PENDING,
    )
    reviewed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    order_item: Mapped["OrderItem"] = relationship(back_populates="alternatives")


class OrderReview(Base):
    __tablename__ = "order_reviews"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("orders.id"), unique=True, nullable=False
    )
    rating: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    comment: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    submitted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    order: Mapped["Order"] = relationship(back_populates="review")
    review_tags: Mapped[list["OrderReviewTag"]] = relationship(
        back_populates="order_review", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint(
            "rating IS NULL OR (rating >= 1 AND rating <= 5)",
            name="chk_order_review_rating_range",
        ),
    )


class ReviewTag(Base):
    __tablename__ = "review_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    order_review_tags: Mapped[list["OrderReviewTag"]] = relationship(
        back_populates="review_tag", cascade="all, delete-orphan"
    )


class OrderReviewTag(Base):
    __tablename__ = "order_review_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_review_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("order_reviews.id"), nullable=False
    )
    review_tag_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("review_tags.id"), nullable=False
    )

    order_review: Mapped["OrderReview"] = relationship(back_populates="review_tags")
    review_tag: Mapped["ReviewTag"] = relationship(back_populates="order_review_tags")

    __table_args__ = (
        UniqueConstraint(
            "order_review_id", "review_tag_id", name="uq_order_review_tags_review_tag"
        ),
    )


class OrderComplaint(Base):
    __tablename__ = "order_complaints"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("orders.id"), unique=True, nullable=False
    )
    status: Mapped[OrderComplaintStatus] = mapped_column(
        Enum(OrderComplaintStatus, native_enum=False),
        default=OrderComplaintStatus.PENDING,
        nullable=False,
    )
    resolution_note: Mapped[str] = mapped_column(Text, default="")
    resolved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    comment: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    order: Mapped["Order"] = relationship(back_populates="complaint")
    complaint_tags: Mapped[list["OrderComplaintTag"]] = relationship(
        back_populates="order_complaint", cascade="all, delete-orphan"
    )
    resolved_by_user: Mapped["User | None"] = relationship(
        "User", foreign_keys=[resolved_by_user_id]
    )


class ComplaintTag(Base):
    __tablename__ = "complaint_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    order_complaint_tags: Mapped[list["OrderComplaintTag"]] = relationship(
        back_populates="complaint_tag", cascade="all, delete-orphan"
    )


class OrderComplaintTag(Base):
    __tablename__ = "order_complaint_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_complaint_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("order_complaints.id"), nullable=False
    )
    complaint_tag_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("complaint_tags.id"), nullable=False
    )

    order_complaint: Mapped["OrderComplaint"] = relationship(
        back_populates="complaint_tags"
    )
    complaint_tag: Mapped["ComplaintTag"] = relationship(
        back_populates="order_complaint_tags"
    )

    __table_args__ = (
        UniqueConstraint(
            "order_complaint_id",
            "complaint_tag_id",
            name="uq_order_complaint_tags_complaint_tag",
        ),
    )
