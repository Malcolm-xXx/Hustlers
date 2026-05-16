from uuid import UUID

from fastapi import APIRouter, Query, Request

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
from src.api.v1.payments.service import (
    add_payment_method_service,
    add_payout_account_service,
    create_payout_request_service,
    delete_payment_method_service,
    delete_payout_account_service,
    get_payment_service,
    get_wallet_summary_service,
    handle_payment_provider_webhook_service,
    initialize_top_up_service,
    list_payment_methods_service,
    list_payout_accounts_service,
    list_payout_requests_service,
    list_wallet_transactions_service,
    set_default_payment_method_service,
    set_default_payout_account_service,
)
from src.utils.dependencies import CurrentUser, DbSession, SellerUser

router = APIRouter()


@router.get("/wallet/", response_model=WalletWithTodayResponse)
async def get_wallet(user: CurrentUser, db: DbSession):
    return await get_wallet_summary_service(db, user)


@router.get("/wallet/transactions/", response_model=list[WalletTransactionResponse])
async def list_wallet_transactions(
    *,
    user: CurrentUser,
    db: DbSession,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    transaction_type: WalletTransactionType | None = Query(default=None, alias="type"),
):
    return await list_wallet_transactions_service(
        db, user, cursor=cursor, limit=limit, transaction_type=transaction_type
    )


@router.post(
    "/wallet/top-ups/initialize/", response_model=WalletTopUpInitializeResponse
)
async def initialize_top_up(
    request: WalletTopUpInitializeRequest,
    *,
    user: CurrentUser,
    db: DbSession,
):
    return await initialize_top_up_service(db, user, request)


@router.get("/payment-methods/", response_model=list[PaymentMethodResponse])
async def list_payment_methods(user: CurrentUser, db: DbSession):
    return await list_payment_methods_service(db, user)


@router.post("/payment-methods/", response_model=PaymentMethodResponse, status_code=201)
async def add_payment_method(
    request: PaymentMethodCreateRequest,
    *,
    user: CurrentUser,
    db: DbSession,
):
    return await add_payment_method_service(db, user, request)


@router.post(
    "/payment-methods/{payment_method_id}/default/",
    response_model=PaymentMethodResponse,
)
async def set_default_payment_method(
    payment_method_id: UUID,
    *,
    user: CurrentUser,
    db: DbSession,
):
    return await set_default_payment_method_service(db, user, payment_method_id)


@router.delete("/payment-methods/{payment_method_id}/", status_code=204)
async def delete_payment_method(
    payment_method_id: UUID,
    *,
    user: CurrentUser,
    db: DbSession,
):
    await delete_payment_method_service(db, user, payment_method_id)


@router.get("/payout-accounts/", response_model=list[PayoutAccountResponse])
async def list_payout_accounts(user: SellerUser, db: DbSession):
    return await list_payout_accounts_service(db, user)


@router.post("/payout-accounts/", response_model=PayoutAccountResponse, status_code=201)
async def add_payout_account(
    request: PayoutAccountCreateRequest,
    *,
    user: SellerUser,
    db: DbSession,
):
    return await add_payout_account_service(db, user, request)


@router.post(
    "/payout-accounts/{payout_account_id}/default/",
    response_model=PayoutAccountResponse,
)
async def set_default_payout_account(
    payout_account_id: UUID,
    *,
    user: SellerUser,
    db: DbSession,
):
    return await set_default_payout_account_service(db, user, payout_account_id)


@router.delete("/payout-accounts/{payout_account_id}/", status_code=204)
async def delete_payout_account(
    payout_account_id: UUID,
    *,
    user: SellerUser,
    db: DbSession,
):
    await delete_payout_account_service(db, user, payout_account_id)


@router.get("/payout-requests/", response_model=list[PayoutRequestResponse])
async def list_payout_requests(
    *,
    user: SellerUser,
    db: DbSession,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    status: PayoutRequestStatus | None = None,
):
    return await list_payout_requests_service(
        db, user, cursor=cursor, limit=limit, status_filter=status
    )


@router.post("/payout-requests/", response_model=PayoutRequestResponse, status_code=201)
async def create_payout_request(
    request: PayoutRequestCreateRequest,
    *,
    user: SellerUser,
    db: DbSession,
):
    return await create_payout_request_service(db, user, request)


@router.get("/payments/{payment_id}/", response_model=PaymentRecordResponse)
async def get_payment(payment_id: UUID, user: CurrentUser, db: DbSession):
    return await get_payment_service(db, user, payment_id)


@router.post("/webhooks/provider/", status_code=200)
async def payment_provider_webhook(request: Request, db: DbSession):
    return await handle_payment_provider_webhook_service(db, request)
