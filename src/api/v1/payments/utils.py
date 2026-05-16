"""Payment utilities and Paystack client."""

import hashlib
import hmac
import uuid
from datetime import datetime
from typing import Any

import httpx

from src.api.v1.payments.schema import (
    PaymentMethodResponse,
    PaymentRecordResponse,
    PayoutAccountResponse,
    PayoutRequestResponse,
    PayoutRequestStatus,
    WalletSummaryResponse,
    WalletTransactionResponse,
    WalletTransactionStatus,
    WalletTransactionType,
)
from src.api.v1.payments.schema import PaymentStatus as PaymentStatusResponse
from src.api.v1.shared.utils.currency import format_money
from src.api.v1.shared.utils.encoding import parse_cursor
from src.core.config import settings
from src.models.payments import (
    Payment,
    PaymentStatus,
    PayoutAccount,
    PayoutRequest,
    SavedPaymentMethod,
    Wallet,
    WalletTransaction,
)


def parse_payment_cursor(
    cursor: str | None,
) -> tuple[datetime | None, uuid.UUID | None]:
    """Parse cursor string into timestamp and ID for payment pagination."""
    if cursor is None:
        return None, None
    try:
        return parse_cursor(cursor)
    except (ValueError, TypeError):
        return None, None


def map_paystack_channel(channel: str) -> str:
    mapping = {
        "card": "card",
        "bank": "bank_transfer",
        "ussd": "ussd",
        "qr": "qr",
        "bank_transfer": "bank_transfer",
        "mobile_money": "wallet",
    }
    return mapping.get(channel, "card")


def payment_method_signature(user_id: uuid.UUID, provider_token: str) -> str:
    digest = hashlib.sha256(f"{user_id}:{provider_token}".encode("utf-8")).hexdigest()
    return digest[:100]


def wallet_summary_payload(wallet: Wallet) -> WalletSummaryResponse:
    return WalletSummaryResponse(
        wallet_id=wallet.id,
        currency_code=wallet.currency_code,
        available_balance=format_money(wallet.available_balance),
        pending_balance=format_money(wallet.pending_balance),
    )


def wallet_transaction_payload(tx: WalletTransaction) -> WalletTransactionResponse:
    return WalletTransactionResponse(
        id=tx.id,
        transaction_type=WalletTransactionType(tx.transaction_type.value),
        amount=format_money(tx.amount),
        balance_after=format_money(tx.balance_after),
        status=WalletTransactionStatus(tx.status.value),
        note=tx.note or None,
        created_at=tx.created_at,
    )


def payment_method_payload(method: SavedPaymentMethod) -> PaymentMethodResponse:
    return PaymentMethodResponse(
        id=method.id,
        method_type=method.method_type,
        brand=method.brand or None,
        last4=method.last4 or None,
        expiry_month=method.expiry_month,
        expiry_year=method.expiry_year,
        is_default=method.is_default,
    )


def payout_account_payload(account: PayoutAccount) -> PayoutAccountResponse:
    return PayoutAccountResponse(
        id=account.id,
        bank_name=account.bank_name or None,
        account_name=account.account_name or None,
        account_last4=account.account_last4 or None,
        is_default=account.is_default,
    )


def payout_request_payload(request: PayoutRequest) -> PayoutRequestResponse:
    return PayoutRequestResponse(
        id=request.id,
        amount=format_money(request.amount),
        status=PayoutRequestStatus(request.status.value),
        requested_at=request.requested_at,
        processed_at=request.processed_at,
        failure_reason=request.failure_reason or None,
    )


def payment_payload(payment: Payment) -> PaymentRecordResponse:
    authorization_url = None
    if payment.status in {
        PaymentStatus.PENDING,
        PaymentStatus.INITIATED,
    } and payment.payment_method in {
        "card",
        "bank_transfer",
    }:
        authorization_url = (
            f"https://checkout.paystack.com/{payment.provider_reference}"
        )

    return PaymentRecordResponse(
        id=payment.id,
        payment_method=payment.payment_method,
        status=PaymentStatusResponse(
            "success"
            if payment.status == PaymentStatus.SUCCEEDED
            else payment.status.value
        ),
        amount=format_money(payment.amount),
        reference=payment.provider_reference,
        authorization_url=authorization_url,
    )


class PaystackClient:
    """Paystack HTTP client using httpx."""

    def __init__(self) -> None:
        self.base_url = "https://api.paystack.co"
        self._client = httpx.AsyncClient(
            headers={
                "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}",
                "Content-Type": "application/json",
            },
            timeout=30.0,
        )

    async def initialize_transaction(
        self,
        email: str,
        amount: int,
        reference: str,
        currency: str = "NGN",
        callback_url: str | None = None,
        metadata: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """Initialize a transaction."""
        payload: dict[str, Any] = {
            "email": email,
            "amount": amount,
            "reference": reference,
            "currency": currency,
        }
        if callback_url:
            payload["callback_url"] = callback_url
        if metadata:
            payload["metadata"] = metadata

        response = await self._client.post(
            f"{self.base_url}/transaction/initialize", json=payload
        )
        response.raise_for_status()
        return response.json()

    async def create_transfer_recipient(
        self,
        *,
        name: str,
        account_number: str,
        bank_code: str,
        currency: str = "NGN",
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "type": "nuban",
            "name": name,
            "account_number": account_number,
            "bank_code": bank_code,
            "currency": currency,
        }
        response = await self._client.post(
            f"{self.base_url}/transferrecipient", json=payload
        )
        response.raise_for_status()
        return response.json()

    async def initiate_transfer(
        self,
        *,
        recipient_code: str,
        amount: int,
        reference: str,
        reason: str,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "source": "balance",
            "recipient": recipient_code,
            "amount": amount,
            "reference": reference,
            "reason": reason,
        }
        response = await self._client.post(f"{self.base_url}/transfer", json=payload)
        response.raise_for_status()
        return response.json()

    async def verify_transaction(self, reference: str) -> dict[str, Any]:
        """Verify a transaction."""
        response = await self._client.get(
            f"{self.base_url}/transaction/verify/{reference}"
        )
        response.raise_for_status()
        return response.json()

    async def charge_authorization(
        self,
        email: str,
        amount: int,
        authorization_code: str,
        reference: str,
        metadata: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """Charge a saved authorization."""
        payload: dict[str, Any] = {
            "email": email,
            "amount": amount,
            "authorization_code": authorization_code,
            "reference": reference,
        }
        if metadata:
            payload["metadata"] = metadata

        response = await self._client.post(
            f"{self.base_url}/transaction/charge_authorization", json=payload
        )
        response.raise_for_status()
        return response.json()

    @staticmethod
    def verify_webhook_signature(payload: bytes, signature: str) -> bool:
        """Verify Paystack webhook signature."""
        secret = settings.PAYSTACK_WEBHOOK_SECRET
        if not secret:
            return False
        expected = hmac.new(secret.encode(), payload, hashlib.sha512).hexdigest()
        return hmac.compare_digest(expected, signature)

    async def close(self) -> None:
        """Close the HTTP client."""
        await self._client.aclose()
