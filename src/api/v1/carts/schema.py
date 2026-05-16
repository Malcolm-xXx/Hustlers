import uuid
from uuid import UUID

from pydantic import BaseModel, Field

from src.models.carts import CartStatus
from src.utils.response import ResponseModel


class ProductSellerSummary(ResponseModel):
    id: UUID
    store_name: str


class ProductCardItem(ResponseModel):
    id: UUID
    name: str
    unit_label: str | None = None
    seller: ProductSellerSummary
    base_price: str
    discounted_price: str | None = None
    is_on_sale: bool
    is_low_stock: bool
    image_url: str | None = None


class CartItemRequest(BaseModel):
    product_id: uuid.UUID
    quantity: int = Field(ge=1)


class CartItemUpdateRequest(BaseModel):
    quantity: int = Field(ge=1)


class CartItemResponse(ResponseModel):
    id: UUID
    product: ProductCardItem
    quantity: int


class CartResponse(ResponseModel):
    id: UUID
    status: CartStatus
    items: list[CartItemResponse]
    subtotal_amount: str


class SavedCartsPageResponse(ResponseModel):
    items: list[CartResponse]
    next_cursor: str | None = None
    has_more: bool = False


class CartGroupItem(ResponseModel):
    product_id: UUID
    quantity: int
    line_total: str


class CartGroup(ResponseModel):
    seller: ProductSellerSummary
    items: list[CartGroupItem]
    subtotal_amount: str
