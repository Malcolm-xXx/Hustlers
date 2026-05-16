"""Payment queries."""

import uuid
from decimal import Decimal
from datetime import datetime, timezone

from fastapi import status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.exceptions import HTTPException
from src.models.payments import (
    PayoutAccount,
    PayoutRequest,
    Payment,
    SavedPaymentMethod,
    Wallet,
    WalletTransaction,
)
from src.models.sellers import SellerProfile


async def get_wallet_for_user(db: AsyncSession, user_id: uuid.UUID) -> Wallet | None:
    """Fetch wallet for a user."""
    result = await db.execute(select(Wallet).where(Wallet.user_id == user_id))
    return result.scalar_one_or_none()


async def get_or_create_wallet_for_user(db: AsyncSession, user_id: uuid.UUID) -> Wallet:
    """Get existing wallet or create new one for user."""
    wallet = await get_wallet_for_user(db, user_id)
    if wallet is None:
        wallet = Wallet(user_id=user_id)
        db.add(wallet)
        await db.flush()
    return wallet


async def get_seller_profile_for_user(
    db: AsyncSession, user_id: uuid.UUID
) -> SellerProfile:
    """Fetch seller profile for user, raising 404 if not found."""
    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user_id)
    )
    seller_profile = result.scalar_one_or_none()
    if seller_profile is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, detail="Seller profile not found."
        )
    return seller_profile


async def get_payment_by_reference(db: AsyncSession, reference: str) -> Payment | None:
    """Fetch payment by provider reference."""
    result = await db.execute(
        select(Payment).where(Payment.provider_reference == reference)
    )
    return result.scalar_one_or_none()


async def get_saved_payment_method_by_signature(
    db: AsyncSession, signature: str, user_id: uuid.UUID
) -> SavedPaymentMethod | None:
    """Fetch saved payment method by signature for a user."""
    result = await db.execute(
        select(SavedPaymentMethod).where(
            SavedPaymentMethod.signature == signature,
            SavedPaymentMethod.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def get_saved_payment_method_by_id(
    db: AsyncSession, method_id: uuid.UUID, user_id: uuid.UUID
) -> SavedPaymentMethod | None:
    """Fetch saved payment method by ID for a user."""
    result = await db.execute(
        select(SavedPaymentMethod).where(
            SavedPaymentMethod.id == method_id,
            SavedPaymentMethod.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def get_saved_payment_methods_by_user(
    db: AsyncSession, user_id: uuid.UUID
) -> list[SavedPaymentMethod]:
    """Fetch all saved payment methods for a user, ordered by default first."""
    result = await db.execute(
        select(SavedPaymentMethod)
        .where(SavedPaymentMethod.user_id == user_id)
        .order_by(
            SavedPaymentMethod.is_default.desc(), SavedPaymentMethod.created_at.desc()
        )
    )
    return list(result.scalars().all())


async def unset_default_payment_methods(db: AsyncSession, user_id: uuid.UUID) -> None:
    """Unset all default payment methods for a user."""
    await db.execute(
        update(SavedPaymentMethod)
        .where(
            SavedPaymentMethod.user_id == user_id,
            SavedPaymentMethod.is_default.is_(True),
        )
        .values(is_default=False)
        .execution_options(synchronize_session=False)
    )


async def get_payout_account_by_id(
    db: AsyncSession, account_id: uuid.UUID, user_id: uuid.UUID
) -> PayoutAccount | None:
    """Fetch payout account by ID for a user."""
    result = await db.execute(
        select(PayoutAccount).where(
            PayoutAccount.id == account_id,
            PayoutAccount.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def get_payout_accounts_by_user(
    db: AsyncSession, user_id: uuid.UUID
) -> list[PayoutAccount]:
    """Fetch all payout accounts for a user, ordered by default first."""
    result = await db.execute(
        select(PayoutAccount)
        .where(PayoutAccount.user_id == user_id)
        .order_by(PayoutAccount.is_default.desc(), PayoutAccount.created_at.desc())
    )
    return list(result.scalars().all())


async def unset_default_payout_accounts(db: AsyncSession, user_id: uuid.UUID) -> None:
    """Unset all default payout accounts for a user."""
    await db.execute(
        update(PayoutAccount)
        .where(PayoutAccount.user_id == user_id, PayoutAccount.is_default.is_(True))
        .values(is_default=False)
        .execution_options(synchronize_session=False)
    )


async def get_payout_requests_by_seller(
    db: AsyncSession,
    seller_id: uuid.UUID,
    *,
    cursor_created_at: datetime | None = None,
    cursor_id: uuid.UUID | None = None,
    limit: int = 20,
    status_filter: str | None = None,
) -> list[PayoutRequest]:
    """Fetch payout requests for a seller with cursor pagination."""
    from sqlalchemy import and_, or_
    from src.models.payments import PayoutRequestStatus

    stmt = select(PayoutRequest).where(PayoutRequest.seller_id == seller_id)
    if status_filter is not None:
        stmt = stmt.where(PayoutRequest.status == PayoutRequestStatus(status_filter))
    stmt = stmt.order_by(PayoutRequest.requested_at.desc(), PayoutRequest.id.desc())

    if cursor_created_at is not None and cursor_id is not None:
        cursor_condition = or_(
            PayoutRequest.requested_at < cursor_created_at,
            and_(
                PayoutRequest.requested_at == cursor_created_at,
                PayoutRequest.id < cursor_id,
            ),
        )
        stmt = stmt.where(cursor_condition)

    result = await db.execute(stmt.limit(max(limit, 1)))
    return list(result.scalars().all())


async def get_wallet_transactions(
    db: AsyncSession,
    wallet_id: uuid.UUID,
    *,
    cursor_created_at: datetime | None = None,
    cursor_id: uuid.UUID | None = None,
    limit: int = 20,
    transaction_type: str | None = None,
) -> list[WalletTransaction]:
    """Fetch wallet transactions with cursor pagination and optional filtering."""
    from sqlalchemy import and_, or_
    from src.models.payments import WalletTransactionType

    stmt = select(WalletTransaction).where(WalletTransaction.wallet_id == wallet_id)
    if transaction_type is not None:
        stmt = stmt.where(
            WalletTransaction.transaction_type
            == WalletTransactionType(transaction_type)
        )
    stmt = stmt.order_by(
        WalletTransaction.created_at.desc(), WalletTransaction.id.desc()
    )

    if cursor_created_at is not None and cursor_id is not None:
        cursor_condition = or_(
            WalletTransaction.created_at < cursor_created_at,
            and_(
                WalletTransaction.created_at == cursor_created_at,
                WalletTransaction.id < cursor_id,
            ),
        )
        stmt = stmt.where(cursor_condition)

    result = await db.execute(stmt.limit(max(limit, 1)))
    return list(result.scalars().all())


async def get_wallet_amount_in_today(db: AsyncSession, wallet_id: uuid.UUID) -> Decimal:
    """Get total wallet transaction amount for today."""
    from src.models.payments import WalletTransactionStatus, WalletTransactionType

    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    result = await db.execute(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount),
                Decimal("0.00"),
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.status == WalletTransactionStatus.SUCCEEDED,
            WalletTransaction.transaction_type.in_(
                [WalletTransactionType.FUNDING, WalletTransactionType.EARNING]
            ),
            WalletTransaction.created_at >= today_start,
        )
    )
    val = result.scalar_one()
    return Decimal("0.00") if val is None else val
