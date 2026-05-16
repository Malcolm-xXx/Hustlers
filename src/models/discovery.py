from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Index, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.auth import User
    from src.models.sellers import SellerProfile
    from src.models.catalog import Product


class FavoriteSeller(Base):
    __tablename__ = "favorite_sellers"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(
        "User",
        back_populates="favorite_sellers",
    )
    seller: Mapped["SellerProfile"] = relationship(
        "SellerProfile",
        back_populates="favorited_by",
    )

    __table_args__ = (
        UniqueConstraint(
            "user_id", "seller_id", name="uq_favorite_sellers_user_seller"
        ),
        Index("idx_fav_sellers_user_created", "user_id", "created_at"),
    )


class FavoriteProduct(Base):
    __tablename__ = "favorite_products"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("products.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship(
        "User",
        back_populates="favorite_products",
    )
    product: Mapped["Product"] = relationship(
        "Product",
        back_populates="favorited_by",
    )

    __table_args__ = (
        UniqueConstraint(
            "user_id", "product_id", name="uq_favorite_products_user_product"
        ),
    )
