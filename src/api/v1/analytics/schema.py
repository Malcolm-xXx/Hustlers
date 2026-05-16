from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field

from src.utils.response import ResponseModel


class EntityType(str, Enum):
    PRODUCT = "product"
    SELLER = "seller"


class SellerInsight(ResponseModel):
    range: str
    total_earnings: str
    earnings_change_pct: str
    total_orders: int
    orders_change_pct: str
    total_hustles: int
    hustles_change_pct: str
    avg_rating: str
    avg_delivery_minutes: int
    success_rate: str


class TopListing(ResponseModel):
    product: dict[str, object]
    gross_sales_amount: str
    views_count: int
    orders_count: int


class HotZone(ResponseModel):
    location: dict[str, object]
    orders_count: int
    change_pct: str


class ServiceAreaOpportunity(ResponseModel):
    location: dict[str, object]
    weekly_orders: int
    customers_count: int
    avg_order_amount: str


class BuyerSpending(ResponseModel):
    total_spent: str
    total_orders: int
    average_order_price: str


class ViewEventCreate(BaseModel):
    entity_type: EntityType
    entity_id: UUID
    source_screen: str = Field(max_length=100)


class ViewEventResponse(ResponseModel):
    accepted: bool
