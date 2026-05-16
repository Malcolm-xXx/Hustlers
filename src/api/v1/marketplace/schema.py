from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from src.api.v1.auth.schema import AddressResponse
from src.models.marketplace import (
    HustleListDispatchChannel,
    HustleListDispatchStatus,
    HustleListStatus,
)
from src.utils.response import ResponseModel


class DispatchAction(str, Enum):
    ACCEPT = "accept"
    DECLINE = "decline"


class SellerSummaryResponse(ResponseModel):
    id: UUID
    store_name: str


class OrderReferenceResponse(ResponseModel):
    id: UUID
    order_number: str
    status: str
    payment_status: str
    created_at: datetime


class HustleListItemCreateRequest(BaseModel):
    requested_name: str = Field(min_length=1, max_length=255)
    quantity_value: Decimal = Field(default=Decimal("1"), gt=0)
    unit_label: str | None = Field(default=None, max_length=50)
    target_price: Decimal | None = Field(default=None, gt=0)
    note: str | None = Field(default=None, max_length=500)


class HustleListItemUpdateRequest(BaseModel):
    requested_name: str | None = Field(default=None, min_length=1, max_length=255)
    quantity_value: Decimal | None = Field(default=None, gt=0)
    unit_label: str | None = Field(default=None, max_length=50)
    target_price: Decimal | None = Field(default=None, gt=0)
    note: str | None = Field(default=None, max_length=500)


class HustleListItemResponse(ResponseModel):
    id: UUID
    requested_name: str
    quantity_value: str
    unit_label: str | None
    target_price: str | None
    note: str | None


class DispatchSummaryResponse(ResponseModel):
    id: UUID
    channel: HustleListDispatchChannel
    status: HustleListDispatchStatus
    target_seller: SellerSummaryResponse | None
    accepted_by_seller: SellerSummaryResponse | None
    sent_at: datetime | None
    responded_at: datetime | None
    expires_at: datetime | None


class ShoppingPlaceSummary(ResponseModel):
    place_id: str
    name: str
    formatted_address: str
    latitude: float
    longitude: float


class HustleListSummaryResponse(ResponseModel):
    id: UUID
    title: str = Field(min_length=1, max_length=255)
    status: HustleListStatus
    items_count: int = Field(ge=0)
    subtotal: str | None
    delivery_fee: str | None
    delivery_window_label: str | None
    shopping_place: ShoppingPlaceSummary | None = None
    created_at: datetime


class HustleListDetailResponse(HustleListSummaryResponse):
    delivery_address: AddressResponse | None = None
    notes: str | None
    items: list[HustleListItemResponse] = Field(default_factory=list)
    dispatches: list[DispatchSummaryResponse] = Field(default_factory=list)


class HustleListRequest(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    shopping_place_id: str | None = Field(default=None, max_length=255)
    shopping_place_name: str | None = Field(default=None, max_length=255)
    shopping_formatted_address: str | None = Field(default=None, max_length=500)
    shopping_latitude: float | None = Field(default=None, ge=-90, le=90)
    shopping_longitude: float | None = Field(default=None, ge=-180, le=180)
    delivery_address_id: UUID | None = None
    delivery_fee: Decimal = Field(default=Decimal("0"), ge=0)
    delivery_window_start: datetime | None = None
    delivery_window_end: datetime | None = None
    delivery_window_label: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=5000)
    items: list[HustleListItemCreateRequest] = Field(
        default_factory=list, max_length=100
    )

    @model_validator(mode="after")
    def validate_shopping_place(self) -> HustleListRequest:
        values = (
            self.shopping_place_id,
            self.shopping_place_name,
            self.shopping_formatted_address,
            self.shopping_latitude,
            self.shopping_longitude,
        )
        provided_count = sum(value is not None for value in values)
        if provided_count not in {0, 5}:
            raise ValueError(
                "shopping_place_id, shopping_place_name, shopping_formatted_address, shopping_latitude, and shopping_longitude must be provided together."
            )
        return self


class HustleListUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    shopping_place_id: str | None = Field(default=None, max_length=255)
    shopping_place_name: str | None = Field(default=None, max_length=255)
    shopping_formatted_address: str | None = Field(default=None, max_length=500)
    shopping_latitude: float | None = Field(default=None, ge=-90, le=90)
    shopping_longitude: float | None = Field(default=None, ge=-180, le=180)
    delivery_address_id: UUID | None = None
    delivery_fee: Decimal | None = Field(default=None, ge=0)
    delivery_window_start: datetime | None = None
    delivery_window_end: datetime | None = None
    delivery_window_label: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=5000)

    @model_validator(mode="after")
    def validate_shopping_place(self) -> HustleListUpdateRequest:
        values = (
            self.shopping_place_id,
            self.shopping_place_name,
            self.shopping_formatted_address,
            self.shopping_latitude,
            self.shopping_longitude,
        )
        provided_count = sum(value is not None for value in values)
        if provided_count not in {0, 5}:
            raise ValueError(
                "shopping_place_id, shopping_place_name, shopping_formatted_address, shopping_latitude, and shopping_longitude must be provided together."
            )
        return self


class HustleListSendRequest(BaseModel):
    seller_id: UUID
    message: str | None = Field(default=None, max_length=2000)
    expires_at: datetime | None = None


class HustleListPublishRequest(BaseModel):
    expires_at: datetime | None = None


class HustleListWithdrawRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=2000)


class SendResponse(ResponseModel):
    list: HustleListDetailResponse
    dispatch: DispatchSummaryResponse


class PublishResponse(ResponseModel):
    list: HustleListDetailResponse
    dispatches: list[DispatchSummaryResponse]


class DispatchDetailResponse(ResponseModel):
    dispatch: DispatchSummaryResponse
    list: HustleListDetailResponse


class DispatchDecisionRequest(BaseModel):
    action: DispatchAction
    note: str | None = Field(default=None, max_length=2000)


class DispatchDecisionResponse(ResponseModel):
    dispatch: DispatchSummaryResponse
    order: OrderReferenceResponse | None = None
