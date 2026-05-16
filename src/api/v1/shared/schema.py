from uuid import UUID

from pydantic import Field

from src.models.catalog import ProductAvailabilityStatus, ProductStockStatus
from src.utils.response import ResponseModel


class LocationSummary(ResponseModel):
    """Location summary for sellers and orders."""

    id: UUID
    name: str
    address_text: str | None = None
    kind: str | None = None
    market_type: str | None = None
    distance_km: float | None = None
    rating: float | None = None
    seller_count: int | None = None


class PresignedUploadURLResponse(ResponseModel):
    """Response containing presigned upload URL and metadata."""

    upload_url: str
    public_id: str
    signature: str
    api_key: str
    timestamp: int
    expires_in: int
    allowed_types: list[str]


class ProductSellerSummaryResponse(ResponseModel):
    """Minimal seller info for product cards."""

    id: UUID
    store_name: str


class SellerCardResponse(ResponseModel):
    """Seller card for list views and discovery."""

    id: UUID
    store_name: str
    profile_image: str | None = None
    status: str = "offline"
    rating: float = Field(default=0.0, ge=0, le=5)
    rating_count: int = Field(default=0, ge=0)
    completed_orders_count: int = Field(default=0, ge=0)
    distance_km: float | None = Field(default=None, ge=0)
    tags: list[str] = Field(default_factory=list)
    is_favorite: bool = False


class ProductCardResponse(ResponseModel):
    """Product card for catalog and discovery."""

    id: UUID
    name: str
    unit_label: str | None = None
    seller: ProductSellerSummaryResponse
    base_price: str
    discounted_price: str | None = None
    is_on_sale: bool = False
    is_low_stock: bool = False
    image_url: str | None = None
    categories: list[str] = Field(default_factory=list)
    description: str | None = None
    shelf_life_text: str | None = None
    stock_status: str = ProductStockStatus.IN_STOCK.value
    availability_status: str = ProductAvailabilityStatus.AVAILABLE.value
    tags: list[str] = Field(default_factory=list)
    seller_rating: str | None = None
    seller_review_count: int | None = None
