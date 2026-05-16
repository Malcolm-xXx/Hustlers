from datetime import datetime
from decimal import Decimal
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from src.api.v1.auth.schema import AddressResponse, UserSummaryResponse
from src.api.v1.carts.schema import CartGroup, CartResponse
from src.api.v1.payments.schema import WalletSummaryResponse
from src.api.v1.shared.schema import LocationSummary, SellerCardResponse
from src.models.orders import (
    OrderItemFulfillmentStatus,
    OrderStatus,
)
from src.models.payments import PaymentStatus
from src.utils.response import ResponseModel


class CheckoutSource(str, Enum):
    CURRENT_CART = "current_cart"
    CART_ID = "cart_id"
    HUSTLE_LIST_ID = "hustle_list_id"


class PaymentMethod(str, Enum):
    WALLET = "wallet"
    CARD = "card"
    BANK_TRANSFER = "bank_transfer"


class OrderAction(str, Enum):
    ACCEPT = "accept"
    START_SHOPPING = "start_shopping"
    ON_THE_WAY = "on_the_way"
    MARK_DELIVERED = "mark_delivered"
    CONFIRM_DELIVERY = "confirm_delivery"
    CANCEL = "cancel"


class OrderDecision(str, Enum):
    APPROVE = "approve"
    REJECT = "reject"


class OrderStatusEventResponse(ResponseModel):
    status: str
    actor_user_id: UUID | None
    note: str = ""
    created_at: datetime


class OrderItemResponse(ResponseModel):
    id: UUID
    display_name: str
    quantity: str
    unit_label: str | None
    base_unit_price: str
    final_unit_price: str
    line_total: str
    fulfillment_status: OrderItemFulfillmentStatus


class OrderReviewResponse(ResponseModel):
    status: str
    rating: int | None
    tags: list[str] = Field(default_factory=list)
    comment: str | None = None
    submitted_at: datetime | None = None


class OrderComplaintResponse(ResponseModel):
    tags: list[str] = Field(default_factory=list)
    comment: str | None = None
    created_at: datetime


class OrderSummaryResponse(ResponseModel):
    id: UUID
    order_number: str
    status: OrderStatus
    payment_status: PaymentStatus
    buyer: UserSummaryResponse
    seller: SellerCardResponse | None = None
    eta_minutes: int | None = None
    delivery_address_text: str = ""
    items_count: int = 0
    total_amount: str = "0.00"
    created_at: datetime


class OrderDetailResponse(OrderSummaryResponse):
    pickup_location: LocationSummary | None = None
    delivery_address: AddressResponse | None = None
    special_instructions: str = ""
    status_events: list[OrderStatusEventResponse] = Field(default_factory=list)
    items: list[OrderItemResponse] = Field(default_factory=list)
    review: OrderReviewResponse | None = None
    complaint: OrderComplaintResponse | None = None


class OrderPageResponse(ResponseModel):
    items: list[OrderSummaryResponse] = Field(default_factory=list)
    count: int = 0
    next_cursor: str | None = None
    has_more: bool = False


class CheckoutPreviewRequest(BaseModel):
    delivery_address_id: UUID | None = None


class CheckoutPreviewResponse(ResponseModel):
    cart: CartResponse | None = None
    order_groups: list[CartGroup] = Field(default_factory=list)
    wallet_balance: str = "0.00"


class CheckoutRequest(BaseModel):
    source: CheckoutSource
    cart_id: UUID | None = None
    hustle_list_id: UUID | None = None
    payment_method: PaymentMethod
    saved_payment_method_id: UUID | None = None
    delivery_address_id: UUID | None = None
    delivery_fee: Decimal | None = Field(default=None, ge=0)
    special_instructions: str | None = Field(default=None, max_length=5000)
    save_payment_method: bool = False

    @model_validator(mode="after")
    def validate_source_fields(self):
        if self.source == CheckoutSource.CART_ID and self.cart_id is None:
            raise ValueError("cart_id is required for source=cart_id.")
        if self.source == CheckoutSource.HUSTLE_LIST_ID and self.hustle_list_id is None:
            raise ValueError("hustle_list_id is required for source=hustle_list_id.")
        return self


class CheckoutPaymentResponse(ResponseModel):
    id: UUID
    payment_method: PaymentMethod
    status: PaymentStatus
    amount: str
    reference: str
    authorization_url: str | None = None


class CheckoutResponse(ResponseModel):
    orders: list[OrderSummaryResponse] = Field(default_factory=list)
    payment: CheckoutPaymentResponse
    wallet: WalletSummaryResponse


class BuyerOrdersSummaryResponse(ResponseModel):
    total_spent: str = "0.00"
    total_orders: int = 0
    average_order_price: str = "0.00"


class OrderStatusMutationRequest(BaseModel):
    action: OrderAction
    seller_eta_minutes: int | None = Field(default=None, ge=1)
    note: str | None = Field(default=None, max_length=5000)


class OrderItemCancelRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=2000)


class OrderItemAlternativeRequest(BaseModel):
    suggested_product_id: UUID | None = None
    suggested_name: str | None = Field(default=None, min_length=1, max_length=255)
    suggested_unit_label: str | None = Field(default=None, max_length=50)
    suggested_price: Decimal | None = Field(default=None, gt=0)
    note: str | None = Field(default=None, max_length=2000)

    @model_validator(mode="after")
    def validate_payload(self) -> "OrderItemAlternativeRequest":
        if (
            self.suggested_product_id is None
            and self.suggested_name is None
            and self.suggested_unit_label is None
            and self.suggested_price is None
        ):
            raise ValueError("Provide at least one suggested field.")
        return self


class AlternativeDecisionRequest(BaseModel):
    decision: OrderDecision


class OrderAdjustmentRequest(BaseModel):
    new_unit_price: Decimal = Field(gt=0)
    reason: str | None = None


class AdjustmentDecisionRequest(BaseModel):
    decision: OrderDecision


class OrderReviewCreateRequest(BaseModel):
    rating: int = Field(ge=1, le=5)
    tags: list[str] | None = Field(default=None, max_length=10)
    comment: str | None = Field(default=None, max_length=5000)


class OrderComplaintCreateRequest(BaseModel):
    tags: list[str] | None = Field(default=None, max_length=10)
    comment: str | None = Field(default=None, max_length=5000)


class OrderReviewResultResponse(ResponseModel):
    order: OrderDetailResponse
    review: OrderReviewResponse


class OrderComplaintResultResponse(ResponseModel):
    order: OrderDetailResponse
    complaint: OrderComplaintResponse


class OrderStatusResponse(ResponseModel):
    order_id: UUID
    status: str
    updated_at: datetime
