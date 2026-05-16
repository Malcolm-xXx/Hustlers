from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl

from src.models.payments import (
    PaymentStatus,
    PayoutRequestStatus,
    WalletCurrencyCode,
    WalletTransactionStatus,
    WalletTransactionType,
)
from src.utils.response import ResponseModel


class WalletSummaryResponse(ResponseModel):
    wallet_id: UUID | None = None
    currency_code: str = WalletCurrencyCode.NGN
    available_balance: str = "0.00"
    pending_balance: str = "0.00"


class WalletWithTodayResponse(ResponseModel):
    wallet: WalletSummaryResponse
    amount_in_today: str = "0.00"


class WalletTransactionResponse(ResponseModel):
    id: UUID
    transaction_type: WalletTransactionType
    amount: str
    balance_after: str
    status: WalletTransactionStatus
    note: str | None = None
    created_at: datetime


class WalletTopUpInitializeRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    payment_method: str
    saved_payment_method_id: UUID | None = None
    callback_url: HttpUrl | None = None


class WalletTopUpInitializeResponse(ResponseModel):
    checkout_url: str


class PaymentMethodResponse(ResponseModel):
    id: UUID
    method_type: str
    brand: str | None = None
    last4: str | None = None
    expiry_month: int | None = Field(default=None, ge=1, le=12)
    expiry_year: int | None = Field(default=None, ge=2020, le=9999)
    is_default: bool = False


class PaymentMethodCreateRequest(BaseModel):
    provider_token: str = Field(min_length=1, max_length=255)
    method_type: str
    brand: str | None = Field(default=None, max_length=50)
    last4: str | None = Field(default=None, min_length=4, max_length=4)
    expiry_month: int | None = Field(default=None, ge=1, le=12)
    expiry_year: int | None = Field(default=None, ge=2020, le=9999)
    is_default: bool = False


class PayoutAccountResponse(ResponseModel):
    id: UUID
    bank_name: str | None = None
    account_name: str | None = None
    account_last4: str | None = None
    is_default: bool = False


class PayoutAccountCreateRequest(BaseModel):
    bank_code: str = Field(min_length=1, max_length=20)
    account_number: str = Field(min_length=10, max_length=20)
    account_name: str = Field(min_length=1, max_length=255)
    is_default: bool = False


class PayoutRequestResponse(ResponseModel):
    id: UUID
    amount: str
    status: PayoutRequestStatus
    requested_at: datetime | None = None
    processed_at: datetime | None = None
    failure_reason: str | None = None


class PayoutRequestCreateRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    payout_account_id: UUID


class PaymentRecordResponse(ResponseModel):
    id: UUID
    payment_method: str
    status: PaymentStatus
    amount: str
    reference: str
    authorization_url: str | None = None


class PaymentWebhookRequest(BaseModel):
    event_type: str = Field(min_length=1, max_length=100)
    data: dict[str, object]
