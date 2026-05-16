from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from src.api.v1.marketplace.schema import (
    HustleListSummaryResponse as MarketplaceHustleListSummaryResponse,
)
from src.api.v1.orders.schema import OrderSummaryResponse
from src.api.v1.shared.schema import LocationSummary
from src.models.sellers import SellerPresenceStatus
from src.utils.response import ResponseModel


class HustleListSummaryResponse(MarketplaceHustleListSummaryResponse):
    pass


class SellerProfileResponse(ResponseModel):
    id: UUID
    store_name: str
    profile_image: str | None = None
    status: str = "offline"
    rating: float | None = None
    rating_count: int = 0
    completed_orders_count: int = 0
    distance_km: float | None = None
    tags: list[str] = Field(default_factory=list)
    is_favorite: bool = False
    user_id: UUID | None = None
    bio: str | None = None
    banner_image: str | None = None
    total_items_count: int = 0
    items_on_sale_count: int = 0
    weekly_store_views: int = 0
    average_delivery_minutes: int = 0
    success_rate: float | None = None
    presence: dict[str, object] | None = None
    service_areas: list[dict[str, object]] = Field(default_factory=list)


class SellerProfileUpdateRequest(BaseModel):
    store_name: str | None = Field(default=None, min_length=1, max_length=255)
    bio: str | None = Field(default=None, max_length=2000)
    profile_image: str | None = Field(default=None, max_length=500)
    banner_image: str | None = Field(default=None, max_length=500)
    is_accepting_orders: bool | None = None


class SellerPresenceUpdateRequest(BaseModel):
    status: SellerPresenceStatus | None = None
    current_location_id: UUID | None = None


class SellerPresenceResponse(ResponseModel):
    status: str
    current_location: LocationSummary | None = None
    last_seen_at: datetime | None = None


class ServiceAreaResponse(ResponseModel):
    id: UUID
    location: LocationSummary | None = None
    is_active: bool = True
    created_at: datetime | None = None


class SellerServiceAreaCreateRequest(BaseModel):
    location_id: UUID


class PaginatedOrderSummaryResponse(ResponseModel):
    items: list[OrderSummaryResponse]
    next_cursor: str | None = None
    has_more: bool = False


class PaginatedHustleListSummaryResponse(ResponseModel):
    items: list[HustleListSummaryResponse]
    next_cursor: str | None = None
    has_more: bool = False


class PaginatedLocationSummaryResponse(ResponseModel):
    items: list[LocationSummary]
    next_cursor: str | None = None
    has_more: bool = False
