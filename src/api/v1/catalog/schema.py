from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Generic, Literal, TypeVar
from uuid import UUID

from pydantic import Field, model_validator

from src.api.v1.shared.schema import (
    ProductCardResponse,
)
from src.models.catalog import (
    ProductAvailabilityStatus,
    ProductPublishStatus,
    ProductStockStatus,
    SaleCampaignStatus,
    SaleCampaignType,
)

from src.utils.response import ResponseModel


class CategoryRequest(ResponseModel):
    name: str
    slug: str | None = None
    parent_id: UUID | None = None
    display_order: int = Field(default=0, ge=0)


class CategoryResponse(ResponseModel):
    id: UUID
    name: str
    slug: str
    parent_id: UUID | None = None
    display_order: int = 0


class TagRequest(ResponseModel):
    name: str
    slug: str | None = None


class TagCreateRequest(ResponseModel):
    name: str
    slug: str | None = None


class TagResponse(ResponseModel):
    id: UUID
    name: str
    slug: str


TagScope = Literal["product", "seller"]


class ProductDetailResponse(ProductCardResponse):
    pass


class ProductCreateRequest(ResponseModel):
    name: str
    category_ids: list[UUID] = Field(default_factory=list)
    category_id: UUID | None = None
    base_price: Decimal = Field(gt=0)
    unit_label: str
    description: str = ""
    shelf_life_text: str = ""
    stock_quantity: int = Field(default=0, ge=0)
    low_stock_threshold: int = Field(default=0, ge=0)
    stock_status: ProductStockStatus = ProductStockStatus.IN_STOCK
    availability_status: ProductAvailabilityStatus = ProductAvailabilityStatus.AVAILABLE
    publish_status: ProductPublishStatus = ProductPublishStatus.DRAFT
    discounted_price: Decimal | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def validate_discounted_price(self) -> ProductCreateRequest:
        if not self.category_ids and self.category_id is not None:
            self.category_ids = [self.category_id]
        self.category_ids = list(dict.fromkeys(self.category_ids))
        if not self.category_ids:
            raise ValueError("category_ids must contain at least one category.")
        if (
            self.discounted_price is not None
            and self.discounted_price >= self.base_price
        ):
            raise ValueError("discounted_price must be less than base_price.")
        return self


class ProductUpdateRequest(ResponseModel):
    name: str | None = None
    category_ids: list[UUID] | None = None
    category_id: UUID | None = None
    base_price: Decimal | None = Field(default=None, gt=0)
    unit_label: str | None = None
    description: str | None = None
    shelf_life_text: str | None = None
    stock_quantity: int | None = Field(default=None, ge=0)
    low_stock_threshold: int | None = Field(default=None, ge=0)
    stock_status: ProductStockStatus | None = None
    availability_status: ProductAvailabilityStatus | None = None
    publish_status: ProductPublishStatus | None = None
    discounted_price: Decimal | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def normalize_category_ids(self) -> ProductUpdateRequest:
        if self.category_ids is None and self.category_id is not None:
            self.category_ids = [self.category_id]
        elif self.category_ids is not None:
            self.category_ids = list(dict.fromkeys(self.category_ids))
            if (
                self.category_id is not None
                and self.category_id not in self.category_ids
            ):
                self.category_ids = [self.category_id, *self.category_ids]
        return self


class ProductImageRequest(ResponseModel):
    image: str | None = None


class ProductImageCreateRequest(ResponseModel):
    is_primary: bool = False
    sort_order: int | None = None


class ProductImageResponse(ResponseModel):
    id: UUID
    image_url: str
    is_primary: bool
    sort_order: int | None = None


class ProductTagRequest(ResponseModel):
    tag_id: UUID


class ProductTagUpsertRequest(ResponseModel):
    tag_ids: list[UUID] = Field(default_factory=list)


class ProductTagResponse(ResponseModel):
    id: UUID
    tag: TagResponse


class SellerTagRequest(ResponseModel):
    tag_id: UUID


class SellerTagUpsertRequest(ResponseModel):
    tag_ids: list[UUID] = Field(default_factory=list)


class SellerTagResponse(ResponseModel):
    id: UUID
    tag: TagResponse


class SaleCampaignItemSummaryResponse(ResponseModel):
    product_id: UUID
    discounted_price: str


class SaleCampaignCreateRequest(ResponseModel):
    name: str
    campaign_type: SaleCampaignType
    discount_percent: Decimal = Field(gt=0, lt=100)
    starts_at: datetime
    ends_at: datetime
    product_ids: list[UUID] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_window(self) -> SaleCampaignCreateRequest:
        if self.starts_at >= self.ends_at:
            raise ValueError("ends_at must be after starts_at.")
        return self


class SaleCampaignUpdateRequest(ResponseModel):
    name: str | None = None
    campaign_type: SaleCampaignType | None = None
    discount_percent: Decimal | None = Field(default=None, gt=0, lt=100)
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    product_ids: list[UUID] | None = None


class SaleCampaignResponse(ResponseModel):
    id: UUID
    name: str
    campaign_type: SaleCampaignType
    discount_percent: str
    starts_at: datetime
    ends_at: datetime
    status: SaleCampaignStatus
    items: list[SaleCampaignItemSummaryResponse] = Field(default_factory=list)


class SaleCampaignStatusRequest(ResponseModel):
    action: Literal["launch", "end", "cancel"]


T = TypeVar("T")


class CursorPageResponse(ResponseModel, Generic[T]):
    count: int
    next_cursor: str | None = None
    has_more: bool = False
    results: list[T] = Field(default_factory=list)


class TagUpsertRequest(ResponseModel):
    tag_ids: list[UUID] = Field(default_factory=list)


class ProductImageUploadRequest(ResponseModel):
    """Request to finalize a product image upload after presigned upload to Cloudinary."""

    image_url: str
    public_id: str
    is_primary: bool = False
    sort_order: int | None = None
