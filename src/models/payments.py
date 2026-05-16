import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Numeric,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    and_,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base


class WalletTransactionType(enum.Enum):
    FUNDING = "funding"
    PAYMENT = "payment"
    REFUND = "refund"
    PAYOUT = "payout"
    EARNING = "earning"
    FEE = "fee"


class PaymentMethodType:
    CARD = "card"
    BANK_TRANSFER = "bank_transfer"
    USSD = "ussd"
    QR = "qr"
    WALLET = "wallet"


class WalletCurrencyCode:
    NGN = "NGN"


class WalletTransactionStatus(enum.Enum):
    PENDING = "pending"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class PaymentStatus(enum.Enum):
    INITIATED = "initiated"
    PENDING = "pending"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    REFUNDED = "refunded"


class PayoutRequestStatus(enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    PAID = "paid"
    FAILED = "failed"


class Wallet(Base):
    __tablename__ = "wallets"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), unique=True, nullable=False
    )
    currency_code: Mapped[str] = mapped_column(String(3), default="NGN", nullable=False)
    available_balance: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0")
    )
    pending_balance: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=Decimal("0")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    transactions: Mapped[list["WalletTransaction"]] = relationship(
        back_populates="wallet", cascade="all, delete-orphan"
    )


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    wallet_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("wallets.id"), nullable=False
    )
    transaction_type: Mapped[WalletTransactionType] = mapped_column(
        Enum(WalletTransactionType, native_enum=False), nullable=False
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    balance_after: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    order_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("orders.id"), nullable=True
    )
    payout_request_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("payout_requests.id"), nullable=True
    )
    provider_reference: Mapped[str] = mapped_column(String(255), default="")
    status: Mapped[WalletTransactionStatus] = mapped_column(
        Enum(WalletTransactionStatus, native_enum=False),
        default=WalletTransactionStatus.PENDING,
    )
    note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    wallet: Mapped["Wallet"] = relationship(back_populates="transactions")

    __table_args__ = (
        CheckConstraint(
            """
            (
                order_id IS NOT NULL AND payout_request_id IS NULL
            ) OR (
                order_id IS NULL AND payout_request_id IS NOT NULL
            ) OR (
                order_id IS NULL AND payout_request_id IS NULL
            )
            """,
            name="chk_wallet_txn_single_reference",
        ),
    )


class SavedPaymentMethod(Base):
    __tablename__ = "saved_payment_methods"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    provider_name: Mapped[str] = mapped_column(String(100), nullable=False)
    method_type: Mapped[str] = mapped_column(String(50), nullable=False)
    provider_token: Mapped[str] = mapped_column(String(255), nullable=False)
    signature: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    brand: Mapped[str] = mapped_column(String(50), default="")
    last4: Mapped[str] = mapped_column(String(4), default="")
    bank: Mapped[str] = mapped_column(String(100), default="")
    expiry_month: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    expiry_year: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        UniqueConstraint("user_id", "signature", name="unique_signature_per_user"),
        Index(
            "unique_default_payment_method_per_user",
            "user_id",
            unique=True,
            postgresql_where=text("is_default"),
        ),
    )


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("orders.id"), nullable=True
    )
    payer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    saved_payment_method_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("saved_payment_methods.id"), nullable=True
    )
    payment_method: Mapped[str] = mapped_column(String(50), nullable=False)
    provider_reference: Mapped[str] = mapped_column(String(255), default="")
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    currency_code: Mapped[str] = mapped_column(String(3), default="NGN", nullable=False)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, native_enum=False),
        default=PaymentStatus.INITIATED,
    )
    paid_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    __table_args__ = (
        Index(
            "unique_succeeded_payment_per_order",
            "order_id",
            unique=True,
            postgresql_where=and_(
                text("order_id IS NOT NULL"),
                text("status = 'succeeded'"),
            ),
        ),
    )


class PayoutAccount(Base):
    __tablename__ = "payout_accounts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    provider_name: Mapped[str] = mapped_column(String(100), nullable=False)
    account_name: Mapped[str] = mapped_column(String(255), nullable=False)
    bank_name: Mapped[str] = mapped_column(String(255), nullable=False)
    account_last4: Mapped[str] = mapped_column(String(4), nullable=False)
    provider_recipient_code: Mapped[str] = mapped_column(String(255), nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    payout_requests: Mapped[list["PayoutRequest"]] = relationship(
        back_populates="payout_account", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index(
            "unique_default_payout_account_per_user",
            "user_id",
            unique=True,
            postgresql_where=text("is_default"),
        ),
    )


class PayoutRequest(Base):
    __tablename__ = "payout_requests"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("seller_profiles.id"), nullable=False
    )
    payout_account_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("payout_accounts.id"), nullable=False
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    status: Mapped[PayoutRequestStatus] = mapped_column(
        Enum(PayoutRequestStatus, native_enum=False),
        default=PayoutRequestStatus.PENDING,
    )
    provider_reference: Mapped[str] = mapped_column(String(255), default="")
    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    processed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    failure_reason: Mapped[str] = mapped_column(Text, default="")

    payout_account: Mapped["PayoutAccount"] = relationship(
        back_populates="payout_requests"
    )

    __table_args__ = (
        Index(
            "unique_pending_processing_payout_per_seller",
            "seller_id",
            unique=True,
            postgresql_where=text("status IN ('pending', 'processing')"),
        ),
    )
