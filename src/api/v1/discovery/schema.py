from __future__ import annotations

from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field

from src.api.v1.shared.schema import (
    ProductCardResponse,
    SellerCardResponse,
)
from src.utils.response import ResponseModel


class SearchType(str, Enum):
    ITEMS = "items"
    SELLERS = "sellers"
    LOCATIONS = "locations"
    ALL = "all"


class LocationSummaryResponse(ResponseModel):
    id: UUID
    name: str
    address_text: str | None = None
    kind: str = "market"
    market_type: str | None = None
    distance_km: float | None = Field(default=None, ge=0)
    rating: float = Field(default=0.0, ge=0, le=5)
    seller_count: int = Field(default=0, ge=0)


class SellerPageResponse(ResponseModel):
    items: list[SellerCardResponse]
    next_cursor: str | None = None
    has_more: bool = False


class ProductPageResponse(ResponseModel):
    items: list[ProductCardResponse]
    next_cursor: str | None = None
    has_more: bool = False


class LocationPageResponse(ResponseModel):
    items: list[LocationSummaryResponse]
    next_cursor: str | None = None
    has_more: bool = False


class DiscoverySearchResponse(ResponseModel):
    items: ProductPageResponse
    sellers: SellerPageResponse
    locations: LocationPageResponse


class FavoriteSellerCreateRequest(BaseModel):
    seller_id: UUID


class FavoriteProductCreateRequest(BaseModel):
    product_id: UUID
