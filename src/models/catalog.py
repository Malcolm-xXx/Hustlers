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
    Index,
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
    from src.models.carts import CartItem
    from src.models.discovery import FavoriteProduct
    from src.models.sellers import SellerProfile


class ProductStockStatus(enum.Enum):
    IN_STOCK = "in_stock"
    LOW_STOCK = "low_stock"
    OUT_OF_STOCK = "out_of_stock"


class ProductPublishStatus(enum.Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class ProductAvailabilityStatus(enum.Enum):
    AVAILABLE = "available"
    HIDDEN = "hidden"


class SaleCampaignType(enum.Enum):
    SINGLE_ITEM = "single_item"
    STORE_WIDE = "store_wide"


class SaleCampaignStatus(enum.Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    ENDED = "ended"
    CANCELLED = "cancelled"


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("categories.id"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    children: Mapped[list["Category"]] = relationship(
        back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped["Category | None"] = relationship(
        back_populates="children", remote_side="[Category.id]"
    )
    product_categories: Mapped[list["ProductCategory"]] = relationship(
        back_populates="category", cascade="all, delete-orphan"
    )
    products: Mapped[list["Product"]] = relationship(
        back_populates="categories", secondary="product_categories"
    )

    __table_args__ = (
        Index("idx_categories_active_order", "is_active", "display_order"),
    )


class Tag(Base):
    __tablename__ = "tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    product_tags: Mapped[list["ProductTag"]] = relationship(
        back_populates="tag", cascade="all, delete-orphan"
    )
    seller_tags: Mapped[list["SellerTag"]] = relationship(
        back_populates="tag", cascade="all, delete-orphan"
    )


class Product(Base):
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    slug: Mapped[str] = mapped_column(String(280), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="")
    unit_label: Mapped[str] = mapped_column(String(50), nullable=False)
    base_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    low_stock_threshold: Mapped[int] = mapped_column(Integer, default=0)
    stock_status: Mapped[ProductStockStatus] = mapped_column(
        Enum(ProductStockStatus, native_enum=False),
        default=ProductStockStatus.IN_STOCK,
    )
    publish_status: Mapped[ProductPublishStatus] = mapped_column(
        Enum(ProductPublishStatus, native_enum=False),
        default=ProductPublishStatus.DRAFT,
    )
    availability_status: Mapped[ProductAvailabilityStatus] = mapped_column(
        Enum(ProductAvailabilityStatus, native_enum=False),
        default=ProductAvailabilityStatus.AVAILABLE,
    )
    shelf_life_text: Mapped[str] = mapped_column(String(255), default="")
    # Cache. Source of truth: ProductDailyMetric
    view_count_cached: Mapped[int] = mapped_column(Integer, default=0)
    # Cache. Source of truth: ProductDailyMetric
    order_count_cached: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    published_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    images: Mapped[list["ProductImage"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    product_tags: Mapped[list["ProductTag"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    seller: Mapped["SellerProfile"] = relationship(back_populates="products")
    product_categories: Mapped[list["ProductCategory"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    categories: Mapped[list["Category"]] = relationship(
        back_populates="products", secondary="product_categories"
    )
    sale_campaign_items: Mapped[list["SaleCampaignItem"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    favorited_by: Mapped[list["FavoriteProduct"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )
    cart_items: Mapped[list["CartItem"]] = relationship(back_populates="product")

    __table_args__ = (
        UniqueConstraint("seller_id", "slug", name="uq_products_seller_slug"),
    )


class ProductCategory(Base):
    __tablename__ = "product_categories"

    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id", ondelete="CASCADE"), primary_key=True
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("categories.id", ondelete="CASCADE"), primary_key=True
    )

    product: Mapped["Product"] = relationship(back_populates="product_categories")
    category: Mapped["Category"] = relationship(back_populates="product_categories")


product_categories = ProductCategory.__table__


class ProductImage(Base):
    __tablename__ = "product_images"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id"), nullable=False
    )
    image_file_url: Mapped[str] = mapped_column(String(500), nullable=False)
    cloudinary_public_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    product: Mapped["Product"] = relationship(back_populates="images")


class ProductTag(Base):
    __tablename__ = "product_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id"), nullable=False
    )
    tag_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tags.id"), nullable=False)

    product: Mapped["Product"] = relationship(back_populates="product_tags")
    tag: Mapped["Tag"] = relationship(back_populates="product_tags")

    __table_args__ = (
        UniqueConstraint("product_id", "tag_id", name="uq_product_tags_product_tag"),
    )


class SellerTag(Base):
    __tablename__ = "seller_tags"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    tag_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tags.id"), nullable=False)

    seller: Mapped["SellerProfile"] = relationship(back_populates="seller_tags")
    tag: Mapped["Tag"] = relationship(back_populates="seller_tags")

    __table_args__ = (
        UniqueConstraint("seller_id", "tag_id", name="uq_seller_tags_seller_tag"),
    )


class SaleCampaign(Base):
    __tablename__ = "sale_campaigns"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    campaign_type: Mapped[SaleCampaignType] = mapped_column(
        Enum(SaleCampaignType, native_enum=False), nullable=False
    )
    discount_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[SaleCampaignStatus] = mapped_column(
        Enum(SaleCampaignStatus, native_enum=False),
        default=SaleCampaignStatus.SCHEDULED,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    items: Mapped[list["SaleCampaignItem"]] = relationship(
        back_populates="campaign", cascade="all, delete-orphan"
    )
    seller: Mapped["SellerProfile"] = relationship(back_populates="sale_campaigns")


class SaleCampaignItem(Base):
    __tablename__ = "sale_campaign_items"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    campaign_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("sale_campaigns.id"), nullable=False
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id"), nullable=False
    )
    original_price_snapshot: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False
    )
    discounted_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    campaign: Mapped["SaleCampaign"] = relationship(back_populates="items")
    product: Mapped["Product"] = relationship(back_populates="sale_campaign_items")

    __table_args__ = (
        UniqueConstraint(
            "campaign_id", "product_id", name="uq_sale_campaign_items_campaign_product"
        ),
    )
