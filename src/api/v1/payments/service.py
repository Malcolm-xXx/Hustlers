"""Payment service layer."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

import httpx
from fastapi import Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.payments.queries import (
    get_or_create_wallet_for_user,
    get_payment_by_reference,
    get_payout_account_by_id,
    get_payout_accounts_by_user,
    get_payout_requests_by_seller,
    get_saved_payment_method_by_id,
    get_saved_payment_method_by_signature,
    get_saved_payment_methods_by_user,
    get_seller_profile_for_user,
    get_wallet_amount_in_today,
    get_wallet_for_user,
    get_wallet_transactions,
    unset_default_payment_methods,
    unset_default_payout_accounts,
)
from src.api.v1.payments.schema import (
    PaymentMethodCreateRequest,
    PaymentMethodResponse,
    PaymentRecordResponse,
    PayoutAccountCreateRequest,
    PayoutAccountResponse,
    PayoutRequestCreateRequest,
    PayoutRequestResponse,
    PayoutRequestStatus,
    WalletTopUpInitializeRequest,
    WalletTopUpInitializeResponse,
    WalletTransactionResponse,
    WalletTransactionType,
    WalletWithTodayResponse,
)
from src.api.v1.payments.utils import (
    PaystackClient,
    map_paystack_channel,
    payment_method_payload,
    payment_method_signature,
    payment_payload,
    payout_account_payload,
    payout_request_payload,
    wallet_summary_payload,
    wallet_transaction_payload,
)
from src.api.v1.shared.utils.currency import format_money
from src.core.exceptions import HTTPException
from src.core.logging import get_logger
from src.models.orders import Order
from src.models.payments import (
    Payment,
    PaymentStatus,
    PayoutAccount,
    PayoutRequest,
    SavedPaymentMethod,
    Wallet,
    WalletTransaction,
    WalletTransactionStatus,
)
from src.models.sellers import SellerProfile

logger = get_logger(__name__)


async def get_wallet_summary_service(
    db: AsyncSession, user: AuthenticatedActor
) -> WalletWithTodayResponse:
    wallet = await get_or_create_wallet_for_user(db, user.id)
    amount_in_today = await get_wallet_amount_in_today(db, wallet.id)
    return WalletWithTodayResponse(
        wallet=wallet_summary_payload(wallet),
        amount_in_today=format_money(amount_in_today),
    )


async def list_wallet_transactions_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    cursor: str | None = None,
    limit: int = 20,
    transaction_type: WalletTransactionType | None = None,
) -> list[WalletTransactionResponse]:
    wallet = await get_wallet_for_user(db, user.id)
    if wallet is None:
        return []
    from src.api.v1.payments.utils import parse_payment_cursor

    cursor_created_at, cursor_id = parse_payment_cursor(cursor)
    txs = await get_wallet_transactions(
        db,
        wallet.id,
        cursor_created_at=cursor_created_at,
        cursor_id=cursor_id,
        limit=limit,
        transaction_type=transaction_type.value if transaction_type else None,
    )
    return [wallet_transaction_payload(tx) for tx in txs]


async def initialize_top_up_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: WalletTopUpInitializeRequest,
) -> WalletTopUpInitializeResponse:
    await get_or_create_wallet_for_user(db, user.id)
    saved_method = None
    if request.saved_payment_method_id is not None:
        saved_method = await get_saved_payment_method_by_id(
            db, request.saved_payment_method_id, user.id
        )

    reference = f"topup_{uuid.uuid4().hex[:16]}"
    client = PaystackClient()
    try:
        response = await client.initialize_transaction(
            email=user.email,
            amount=int((request.amount * Decimal("100")).quantize(Decimal("1"))),
            reference=reference,
            callback_url=str(request.callback_url) if request.callback_url else None,
            metadata={"purpose": "wallet_topup", "user_id": str(user.id)},
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail="Unable to initialize payment provider request.",
        ) from exc
    finally:
        await client.close()

    if response.get("status") is not True:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail=str(response.get("message") or "Failed to initialize payment."),
        )

    payment = Payment(
        id=uuid.uuid4(),
        payer_user_id=user.id,
        saved_payment_method_id=saved_method.id if saved_method is not None else None,
        payment_method=request.payment_method,
        provider_reference=str(response.get("data", {}).get("reference") or reference),
        amount=request.amount,
        currency_code="NGN",
        status=PaymentStatus.PENDING,
    )
    db.add(payment)

    authorization_url = str(response.get("data", {}).get("authorization_url") or "")
    return WalletTopUpInitializeResponse(
        checkout_url=authorization_url
        or f"https://checkout.paystack.com/{payment.provider_reference}"
    )


async def list_payment_methods_service(
    db: AsyncSession, user: AuthenticatedActor
) -> list[PaymentMethodResponse]:
    methods = await get_saved_payment_methods_by_user(db, user.id)
    return [payment_method_payload(method) for method in methods]


async def add_payment_method_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: PaymentMethodCreateRequest,
) -> PaymentMethodResponse:
    signature = payment_method_signature(user.id, request.provider_token)
    method = await get_saved_payment_method_by_signature(db, signature, user.id)

    if request.is_default:
        await unset_default_payment_methods(db, user.id)

    if method is None:
        method = SavedPaymentMethod(
            id=uuid.uuid4(),
            user_id=user.id,
            provider_name="paystack",
            method_type=request.method_type,
            provider_token=request.provider_token,
            signature=signature,
            brand=request.brand or "",
            last4=request.last4 or "",
            expiry_month=request.expiry_month,
            expiry_year=request.expiry_year,
            email=user.email,
            is_default=request.is_default,
        )
        db.add(method)
    else:
        method.provider_name = "paystack"
        method.method_type = request.method_type
        method.provider_token = request.provider_token
        method.signature = signature
        method.brand = request.brand or ""
        method.last4 = request.last4 or ""
        method.expiry_month = request.expiry_month
        method.expiry_year = request.expiry_year
        method.email = user.email
        method.is_default = request.is_default

    return payment_method_payload(method)


async def set_default_payment_method_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    payment_method_id: uuid.UUID,
) -> PaymentMethodResponse:
    method = await get_saved_payment_method_by_id(db, payment_method_id, user.id)
    if method is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Payment method not found."
        )

    await unset_default_payment_methods(db, user.id)
    method.is_default = True

    return payment_method_payload(method)


async def delete_payment_method_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    payment_method_id: uuid.UUID,
) -> None:
    method = await get_saved_payment_method_by_id(db, payment_method_id, user.id)
    if method is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Payment method not found."
        )
    await db.delete(method)


async def list_payout_accounts_service(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> list[PayoutAccountResponse]:
    await get_seller_profile_for_user(db, user.id)
    accounts = await get_payout_accounts_by_user(db, user.id)
    return [payout_account_payload(account) for account in accounts]


async def add_payout_account_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: PayoutAccountCreateRequest,
) -> PayoutAccountResponse:
    await get_seller_profile_for_user(db, user.id)

    if request.is_default:
        await unset_default_payout_accounts(db, user.id)

    client = PaystackClient()
    try:
        response = await client.create_transfer_recipient(
            name=request.account_name,
            account_number=request.account_number,
            bank_code=request.bank_code,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail="Unable to initialize payment provider request.",
        ) from exc
    finally:
        await client.close()

    if response.get("status") is not True:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail=str(response.get("message") or "Failed to create payout account."),
        )

    data = response.get("data", {})
    details = data.get("details") if isinstance(data.get("details"), dict) else {}
    recipient_code = str(data.get("recipient_code") or "").strip()
    if not recipient_code:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail="Payment provider did not return a recipient code.",
        )

    payout_account = PayoutAccount(
        id=uuid.uuid4(),
        user_id=user.id,
        provider_name="paystack",
        account_name=str(details.get("account_name") or request.account_name),
        bank_name=str(details.get("bank_name") or request.bank_code),
        account_last4=request.account_number[-4:],
        provider_recipient_code=recipient_code,
        is_default=request.is_default,
    )
    db.add(payout_account)
    return payout_account_payload(payout_account)


async def set_default_payout_account_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    payout_account_id: uuid.UUID,
) -> PayoutAccountResponse:
    await get_seller_profile_for_user(db, user.id)
    account = await get_payout_account_by_id(db, payout_account_id, user.id)
    if account is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Payout account not found."
        )

    await unset_default_payout_accounts(db, user.id)
    account.is_default = True

    return payout_account_payload(account)


async def delete_payout_account_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    payout_account_id: uuid.UUID,
) -> None:
    await get_seller_profile_for_user(db, user.id)
    account = await get_payout_account_by_id(db, payout_account_id, user.id)
    if account is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Payout account not found."
        )
    await db.delete(account)


async def list_payout_requests_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    cursor: str | None = None,
    limit: int = 20,
    status_filter: PayoutRequestStatus | None = None,
) -> list[PayoutRequestResponse]:
    from src.api.v1.payments.utils import parse_payment_cursor

    cursor_created_at, cursor_id = parse_payment_cursor(cursor)
    seller_profile = await get_seller_profile_for_user(db, user.id)
    requests = await get_payout_requests_by_seller(
        db,
        seller_profile.id,
        cursor_created_at=cursor_created_at,
        cursor_id=cursor_id,
        limit=limit,
        status_filter=status_filter.value if status_filter else None,
    )
    return [payout_request_payload(req) for req in requests]


async def create_payout_request_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: PayoutRequestCreateRequest,
) -> PayoutRequestResponse:
    seller_profile = await get_seller_profile_for_user(db, user.id)

    payout_account = await get_payout_account_by_id(
        db, request.payout_account_id, user.id
    )
    if payout_account is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"payout_account_id": ["Payout account not found."]},
        )

    wallet = await get_wallet_for_user(db, user.id)
    if wallet is None or wallet.available_balance < request.amount:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance for payout.",
        )

    reference = f"payout_{uuid.uuid4().hex[:16]}"
    client = PaystackClient()
    try:
        response = await client.initiate_transfer(
            recipient_code=payout_account.provider_recipient_code,
            amount=int((request.amount * Decimal("100")).quantize(Decimal("1"))),
            reference=reference,
            reason="Seller payout request",
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail="Unable to initialize payment provider request.",
        ) from exc
    finally:
        await client.close()

    if response.get("status") is not True:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            detail=str(response.get("message") or "Failed to initiate payout."),
        )

    data = response.get("data", {})
    provider_reference = str(data.get("reference") or reference)
    provider_status = str(data.get("status") or "pending").strip().lower()
    payout_status = (
        PayoutRequestStatus.PAID
        if provider_status in {"success", "successful", "paid"}
        else PayoutRequestStatus.PROCESSING
    )
    processed_at = (
        datetime.now(timezone.utc)
        if payout_status == PayoutRequestStatus.PAID
        else None
    )

    wallet.available_balance = wallet.available_balance - request.amount
    transaction = WalletTransaction(
        id=uuid.uuid4(),
        wallet_id=wallet.id,
        transaction_type=WalletTransactionType.PAYOUT,
        amount=request.amount,
        balance_after=wallet.available_balance,
        status=(
            WalletTransactionStatus.SUCCEEDED
            if payout_status == PayoutRequestStatus.PAID
            else WalletTransactionStatus.PENDING
        ),
        note="Seller payout request",
    )
    db.add(transaction)

    payout_request = PayoutRequest(
        id=uuid.uuid4(),
        seller_id=seller_profile.id,
        payout_account_id=payout_account.id,
        amount=request.amount,
        status=payout_status,
        provider_reference=provider_reference,
        processed_at=processed_at,
        failure_reason="",
    )
    db.add(payout_request)
    return payout_request_payload(payout_request)


async def get_payment_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    payment_id: uuid.UUID,
) -> PaymentRecordResponse:
    from sqlalchemy import select

    stmt = select(Payment).where(
        Payment.id == payment_id,
        Payment.payer_user_id == user.id,
    )
    result = await db.execute(stmt)
    payment = result.scalar_one_or_none()
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Payment not found.")
    return payment_payload(payment)


async def handle_payment_provider_webhook_service(
    db: AsyncSession,
    request: Request,
) -> dict[str, bool]:
    raw_body = await request.body()
    signature = (
        request.headers.get("x-paystack-signature")
        or request.headers.get("x-payment-signature")
        or ""
    )
    if not PaystackClient.verify_webhook_signature(raw_body, signature):
        logger.warning("payment_webhook_rejected", reason="invalid_signature")
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid webhook signature."
        )

    payload = await request.json()
    payload_map = payload if isinstance(payload, dict) else {}
    event = str(payload_map.get("event") or "").strip().lower()
    data = payload_map.get("data")
    data_map = data if isinstance(data, dict) else {}
    reference = str(
        data_map.get("reference")
        or data_map.get("trxref")
        or data_map.get("transfer_code")
        or ""
    ).strip()

    if not reference:
        return {"received": True}

    if event in {"charge.success", "transaction.success"}:
        payment = await get_payment_by_reference(db, reference)
        if payment is not None and payment.status != PaymentStatus.SUCCEEDED:
            payment.status = PaymentStatus.SUCCEEDED
            payment.paid_at = datetime.now(timezone.utc)
            if payment.order_id is not None:
                order_result = await db.execute(
                    select(Order).where(Order.id == payment.order_id)
                )
                _ = order_result.scalar_one_or_none()
            else:
                await credit_wallet(db, payment.payer_user_id, payment.amount)
            logger.info(
                "payment_webhook_processed",
                webhook_event=event,
                reference=reference,
                payment_id=str(payment.id),
                status=payment.status.value,
            )

    if event in {"charge.failed", "transaction.failed"}:
        payment = await get_payment_by_reference(db, reference)
        if payment is not None and payment.status != PaymentStatus.FAILED:
            payment.status = PaymentStatus.FAILED
            if payment.order_id is not None:
                order_result = await db.execute(
                    select(Order).where(Order.id == payment.order_id)
                )
                _ = order_result.scalar_one_or_none()
            logger.info(
                "payment_webhook_processed",
                webhook_event=event,
                reference=reference,
                payment_id=str(payment.id),
                status=payment.status.value,
            )

    if event == "transfer.success":
        stmt = select(PayoutRequest).where(
            PayoutRequest.provider_reference == reference
        )
        result = await db.execute(stmt)
        payout_request = result.scalar_one_or_none()
        if (
            payout_request is not None
            and payout_request.status != PayoutRequestStatus.PAID
        ):
            payout_request.status = PayoutRequestStatus.PAID
            payout_request.processed_at = datetime.now(timezone.utc)
            payout_request.failure_reason = ""
            logger.info(
                "payout_webhook_processed",
                webhook_event=event,
                reference=reference,
                payout_request_id=str(payout_request.id),
                status=payout_request.status.value,
            )

    if event in {"transfer.failed", "transfer.reversed"}:
        stmt = select(PayoutRequest).where(
            PayoutRequest.provider_reference == reference
        )
        result = await db.execute(stmt)
        payout_request = result.scalar_one_or_none()
        if (
            payout_request is not None
            and payout_request.status != PayoutRequestStatus.FAILED
        ):
            seller_result = await db.execute(
                select(SellerProfile).where(
                    SellerProfile.id == payout_request.seller_id
                )
            )
            seller_profile = seller_result.scalar_one_or_none()
            if seller_profile is not None:
                wallet_result = await db.execute(
                    select(Wallet).where(Wallet.user_id == seller_profile.user_id)
                )
                wallet = wallet_result.scalar_one_or_none()
                if wallet is not None:
                    wallet.available_balance += payout_request.amount
                    db.add(
                        WalletTransaction(
                            id=uuid.uuid4(),
                            wallet_id=wallet.id,
                            transaction_type=WalletTransactionType.REFUND,
                            amount=payout_request.amount,
                            balance_after=wallet.available_balance,
                            status=WalletTransactionStatus.SUCCEEDED,
                            note="Payout reversal",
                        )
                    )
            payout_request.status = PayoutRequestStatus.FAILED
            payout_request.processed_at = datetime.now(timezone.utc)
            payout_request.failure_reason = str(
                data_map.get("message") or payload_map.get("message") or ""
            )
            logger.warning(
                "payout_webhook_processed",
                webhook_event=event,
                reference=reference,
                payout_request_id=str(payout_request.id),
                status=payout_request.status.value,
            )

    return {"received": True}


async def charge_saved_card(
    db: AsyncSession,
    user: AuthenticatedActor,
    authorization_code: str,
    amount: Decimal,
    order_id: Optional[uuid.UUID] = None,
    metadata: Optional[dict] = None,
) -> tuple[str, PaymentStatus]:
    """Charge a saved card."""
    client = PaystackClient()

    amount_in_kobo = int(amount * 100)
    reference = f"pay_{uuid.uuid4().hex[:16]}"

    try:
        response = await client.charge_authorization(
            email=user.email,
            amount=amount_in_kobo,
            authorization_code=authorization_code,
            reference=reference,
            metadata=metadata,
        )
    finally:
        await client.close()

    data = response.get("data", {})

    if response.get("status") is not True:
        raise ValueError(response.get("message", "Failed to charge card"))

    channel = data.get("channel", "card")

    payment = Payment(
        id=uuid.uuid4(),
        payer_user_id=user.id,
        order_id=order_id,
        payment_method=map_paystack_channel(channel),
        provider_reference=reference,
        amount=amount,
        currency_code="NGN",
    )

    payment_status = data.get("status")
    if payment_status == "success":
        payment.status = PaymentStatus.SUCCEEDED
        payment.paid_at = datetime.now(timezone.utc)

        authorization = data.get("authorization", {})
        if authorization.get("reusable"):
            signature = authorization.get("signature", "")
            existing_card = await get_saved_payment_method_by_signature(
                db, signature, user.id
            )

            if not existing_card:
                saved_card = SavedPaymentMethod(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    provider_name="paystack",
                    method_type="card",
                    provider_token=authorization.get("authorization_code", ""),
                    signature=signature,
                    brand=authorization.get("card_type", ""),
                    last4=authorization.get("last4", ""),
                    bank=authorization.get("bank", ""),
                    expiry_month=authorization.get("exp_month"),
                    expiry_year=authorization.get("exp_year"),
                    email=user.email,
                )
                db.add(saved_card)

        await credit_wallet(db, user.id, amount)
    else:
        payment.status = PaymentStatus.FAILED

    db.add(payment)
    return reference, payment.status


async def get_saved_payment_methods(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> list[SavedPaymentMethod]:
    """Get user's saved payment methods."""
    return await get_saved_payment_methods_by_user(db, user_id)


async def delete_saved_payment_method(
    db: AsyncSession,
    user_id: uuid.UUID,
    method_id: uuid.UUID,
) -> bool:
    """Delete a saved payment method."""
    method = await get_saved_payment_method_by_id(db, method_id, user_id)

    if not method:
        return False

    await db.delete(method)
    return True


async def credit_wallet(
    db: AsyncSession,
    user_id: uuid.UUID,
    amount: Decimal,
) -> Wallet:
    """Credit user's wallet with payment amount."""
    wallet = await get_or_create_wallet_for_user(db, user_id)

    wallet.available_balance += amount

    transaction = WalletTransaction(
        id=uuid.uuid4(),
        wallet_id=wallet.id,
        transaction_type=WalletTransactionType.FUNDING,
        amount=amount,
        balance_after=wallet.available_balance,
        status=WalletTransactionStatus.SUCCEEDED,
        note="Payment received",
    )
    db.add(transaction)

    return wallet


async def verify_payment(
    db: AsyncSession,
    reference: str,
) -> Payment:
    """Verify a payment with Paystack and update status."""
    client = PaystackClient()

    try:
        response = await client.verify_transaction(reference)
    finally:
        await client.close()

    data = response.get("data", {})

    if response.get("status") is not True:
        raise ValueError(response.get("message", "Payment verification failed"))

    payment = await get_payment_by_reference(db, reference)

    if not payment:
        payer_user_id = uuid.UUID(data.get("customer", {}).get("id", "0"))
        channel = data.get("channel", "card")
        payment = Payment(
            id=uuid.uuid4(),
            payer_user_id=payer_user_id,
            payment_method=map_paystack_channel(channel),
            provider_reference=reference,
            amount=Decimal(str(data.get("amount", 0))) / 100,
            currency_code=data.get("currency", "NGN"),
            status=PaymentStatus.FAILED,
        )
        db.add(payment)
        return payment

    payment_status = data.get("status")
    payment.status = (
        PaymentStatus.SUCCEEDED if payment_status == "success" else PaymentStatus.FAILED
    )

    if payment_status == "success":
        channel = data.get("channel", "card")
        payment.payment_method = map_paystack_channel(channel)

    payment.paid_at = (
        datetime.now(timezone.utc) if payment_status == "success" else None
    )

    if payment_status == "success":
        authorization = data.get("authorization", {})
        if authorization.get("reusable"):
            signature = authorization.get("signature", "")
            existing_card = await get_saved_payment_method_by_signature(
                db, signature, payment.payer_user_id
            )

            if not existing_card:
                saved_card = SavedPaymentMethod(
                    id=uuid.uuid4(),
                    user_id=payment.payer_user_id,
                    provider_name="paystack",
                    method_type="card",
                    provider_token=authorization.get("authorization_code", ""),
                    signature=signature,
                    brand=authorization.get("card_type", ""),
                    last4=authorization.get("last4", ""),
                    bank=authorization.get("bank", ""),
                    expiry_month=authorization.get("exp_month"),
                    expiry_year=authorization.get("exp_year"),
                    email=authorization.get("email", ""),
                )
                db.add(saved_card)

        amount_val = data.get("amount", 0)
        if amount_val:
            await credit_wallet(
                db, payment.payer_user_id, Decimal(str(amount_val)) / 100
            )

    return payment


async def initialize_payment(
    db: AsyncSession,
    user: AuthenticatedActor,
    amount: Decimal,
    email: str,
    order_id: Optional[uuid.UUID] = None,
    metadata: Optional[dict] = None,
    currency: str = "NGN",
    callback_url: str | None = None,
) -> tuple[str, str, int]:
    """Initialize a new payment with Paystack."""
    client = PaystackClient()

    amount_in_kobo = int(amount * 100)
    reference = f"pay_{uuid.uuid4().hex[:16]}"

    try:
        response = await client.initialize_transaction(
            email=email,
            amount=amount_in_kobo,
            reference=reference,
            currency=currency,
            callback_url=callback_url,
            metadata=metadata,
        )
    finally:
        await client.close()

    data = response.get("data", {})

    if response.get("status") is not True:
        raise ValueError(response.get("message", "Failed to initialize payment"))

    channel = data.get("channel", "card")
    payment = Payment(
        id=uuid.uuid4(),
        payer_user_id=user.id,
        order_id=order_id,
        payment_method=map_paystack_channel(channel),
        provider_reference=reference,
        amount=amount,
        currency_code=currency,
        status=PaymentStatus.PENDING,
    )
    db.add(payment)

    return (
        reference,
        data.get("authorization_url", ""),
        amount_in_kobo,
    )
