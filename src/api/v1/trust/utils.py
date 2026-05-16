import secrets
import uuid
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import TYPE_CHECKING

from fastapi import status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.shared.serializers import build_user_summary
from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
from src.core.exceptions import HTTPException as CoreHTTPException
from src.models.trust import UserVerification, UserVerificationStatus

if TYPE_CHECKING:
    from src.models.auth import User
    from src.models.trust import UserBlock, UserReport, UserReportStatus

    from src.api.v1.trust.schema import (
        BlockResponse,
        ReportResponse,
        VerificationStatusResponse,
    )


@dataclass(slots=True)
class VerificationSubmissionResult:
    status: UserVerificationStatus
    provider_reference: str
    payload: dict[str, object]
    failure_reason: str = ""


@dataclass(slots=True)
class VerificationWebhookEvent:
    provider_reference: str
    status: UserVerificationStatus
    payload: dict[str, object]
    event_id: str = ""
    failure_reason: str = ""


def normalize_status(raw_status: object) -> UserVerificationStatus:
    if isinstance(raw_status, bool):
        return (
            UserVerificationStatus.VERIFIED
            if raw_status
            else UserVerificationStatus.FAILED
        )

    value = str(raw_status or "").strip().lower()
    if value in {"verified", "success", "completed", "approved", "pass", "passed"}:
        return UserVerificationStatus.VERIFIED
    if value in {"failed", "declined", "rejected", "error", "invalid"}:
        return UserVerificationStatus.FAILED
    if value in {"pending", "processing", "in_progress", "queued", "submitted"}:
        return UserVerificationStatus.PENDING
    return UserVerificationStatus.PENDING


def verification_response(
    verification: UserVerification,
) -> "VerificationStatusResponse":
    from src.api.v1.trust.schema import VerificationStatusResponse

    return VerificationStatusResponse(
        status=UserVerificationStatus(verification.status.value),
        id_document_type=verification.id_document_type,
        id_document_uploaded=bool(verification.id_document_image_url),
        face_capture_uploaded=bool(verification.face_capture_image_url),
        failure_reason=verification.failure_reason or None,
        submitted_at=verification.submitted_at,
        verified_at=verification.verified_at,
    )


def ensure_non_self_target(
    target_id: uuid.UUID,
    user_id: uuid.UUID,
    *,
    field_name: str,
    message: str,
) -> None:
    if target_id == user_id:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={field_name: [message]},
        )


def serialize_block(block: "UserBlock") -> "BlockResponse":
    from src.api.v1.trust.schema import BlockResponse

    return BlockResponse(
        blocked_user=build_user_summary(block.blocked_user),
        created_at=block.created_at,
    )


def serialize_report(report: "UserReport") -> "ReportResponse":
    from src.api.v1.trust.schema import ReportResponse

    return ReportResponse(
        id=report.id,
        reported_user=build_user_summary(report.reported_user),
        reason_type=report.reason_type,
        details=report.details,
        status=UserReportStatus(report.status.value),
        created_at=report.created_at,
    )


def encode_timestamp_cursor(timestamp: datetime, row_id: uuid.UUID) -> str:
    return encode_cursor(timestamp, row_id)


def parse_timestamp_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        return parse_cursor(cursor)
    except (ValueError, TypeError) as exc:
        raise CoreHTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        ) from exc


def apply_webhook_event(
    verification: UserVerification,
    event: VerificationWebhookEvent,
) -> bool:
    payload = dict(verification.provider_payload_json or {})
    event_ids = payload.get("webhook_event_ids", [])
    if not isinstance(event_ids, list):
        event_ids = []

    if event.event_id and event.event_id in event_ids:
        return False

    if event.event_id:
        event_ids.append(event.event_id)
        payload["webhook_event_ids"] = event_ids[-50:]

    payload["last_webhook_payload"] = event.payload
    verification.provider_payload_json = payload
    verification.status = UserVerificationStatus(event.status.value)
    if event.status == UserVerificationStatus.VERIFIED:
        verification.verified_at = datetime.now(timezone.utc)
        verification.failure_reason = ""
    elif event.status == UserVerificationStatus.FAILED:
        verification.verified_at = None
        if event.failure_reason:
            verification.failure_reason = event.failure_reason
    else:
        verification.verified_at = None

    return True


def get_verification_provider(
    provider_name: str | None = None,
) -> "MockVerificationProvider":
    normalized = (provider_name or "mock").strip().lower()
    if normalized != "mock":
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"provider_name": ["Unsupported verification provider."]},
        )
    return MockVerificationProvider()


def infer_verification_provider_name(
    headers: Mapping[str, str],
    explicit_provider_name: str | None = None,
) -> str:
    if explicit_provider_name:
        return explicit_provider_name.strip().lower()

    provider_header = headers.get("X-Verification-Provider") or headers.get(
        "Verification-Provider"
    )
    if provider_header:
        return provider_header.strip().lower()
    return "mock"


class MockVerificationProvider:
    provider_name = "mock"

    def submit_verification(
        self, verification: UserVerification
    ) -> VerificationSubmissionResult:
        provider_reference = f"mock_{verification.user_id}_{secrets.token_hex(8)}"
        return VerificationSubmissionResult(
            status=UserVerificationStatus.PENDING,
            provider_reference=provider_reference,
            payload={
                "provider": self.provider_name,
                "mode": "simulated",
                "status": UserVerificationStatus.PENDING.value,
            },
        )

    def verify_webhook_signature(
        self, raw_body: bytes, headers: Mapping[str, str]
    ) -> bool:
        return True

    def parse_webhook_event(
        self, payload: Mapping[str, object]
    ) -> VerificationWebhookEvent | None:
        provider_reference = (
            payload.get("provider_reference")
            or payload.get("reference_id")
            or payload.get("reference")
        )
        if not provider_reference:
            return None

        status_value = normalize_status(
            payload.get("status") or payload.get("verification_status")
        )
        event_id = str(payload.get("id") or payload.get("event_id") or "")
        failure_reason = str(
            payload.get("failure_reason") or payload.get("error") or ""
        )

        return VerificationWebhookEvent(
            provider_reference=str(provider_reference),
            status=status_value,
            payload=dict(payload),
            event_id=event_id,
            failure_reason=failure_reason,
        )


async def ensure_user_exists(
    db: AsyncSession, user_id: uuid.UUID, field_name: str, message: str
) -> None:
    from src.models.auth import User

    result = await db.execute(select(User.id).where(User.id == user_id).limit(1))
    if result.scalar_one_or_none() is None:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST, detail={field_name: [message]}
        )


async def ensure_order_is_reportable(
    db: AsyncSession,
    user_id: uuid.UUID,
    order_id: uuid.UUID,
) -> None:
    from src.models.orders import Order

    result = await db.execute(select(Order.id).where(Order.id == order_id).limit(1))
    if result.scalar_one_or_none() is None:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST, detail={"order_id": ["Order not found."]}
        )

    result = await db.execute(
        select(Order.id).where(Order.id == order_id, Order.buyer_id == user_id).limit(1)
    )
    if result.scalar_one_or_none() is None:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"order_id": ["You can only report orders you are involved in."]},
        )


async def ensure_conversation_is_reportable(
    db: AsyncSession,
    user_id: uuid.UUID,
    conversation_id: uuid.UUID,
) -> None:
    from src.models.messaging import Conversation, ConversationMember

    result = await db.execute(
        select(Conversation.id).where(Conversation.id == conversation_id).limit(1)
    )
    if result.scalar_one_or_none() is None:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"conversation_id": ["Conversation not found."]},
        )

    result = await db.execute(
        select(ConversationMember.id)
        .where(
            ConversationMember.conversation_id == conversation_id,
            ConversationMember.user_id == user_id,
        )
        .limit(1)
    )
    if result.scalar_one_or_none() is None:
        raise CoreHTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={
                "conversation_id": [
                    "You can only report conversations you are involved in."
                ]
            },
        )


async def activate_seller_from_verification(
    db: AsyncSession,
    user: "User",
    verification_status: UserVerificationStatus,
) -> None:
    from src.models.auth import UserRole
    from src.models.sellers import SellerPresence, SellerProfile

    if verification_status != UserVerificationStatus.VERIFIED:
        return

    if user.role == UserRole.BUYER:
        user.role = UserRole.SELLER

    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user.id).limit(1)
    )
    seller_profile = result.scalar_one_or_none()
    if seller_profile is None:
        seller_profile = SellerProfile(user_id=user.id, store_name=user.full_name)
        db.add(seller_profile)
        await db.flush()
    elif not seller_profile.store_name:
        seller_profile.store_name = user.full_name

    result = await db.execute(
        select(SellerPresence)
        .where(SellerPresence.seller_id == seller_profile.id)
        .limit(1)
    )
    seller_presence = result.scalar_one_or_none()
    if seller_presence is None:
        db.add(SellerPresence(seller_id=seller_profile.id))


async def create_user_verification(
    db: AsyncSession, user_id: uuid.UUID
) -> UserVerification:
    """Create a new verification record for a user."""
    verification = UserVerification(user_id=user_id)
    db.add(verification)
    await db.flush()
    return verification


async def get_or_create_verification(
    db: AsyncSession, user: "User"
) -> UserVerification:
    """Get existing verification or create a new one."""
    verification = await get_user_verification(db, user.id)
    if verification is None:
        verification = await create_user_verification(db, user.id)
    return verification


async def get_user_verification(
    db: AsyncSession, user_id: uuid.UUID
) -> UserVerification | None:
    """Fetch the most recent verification for a user."""
    result = await db.execute(
        select(UserVerification)
        .where(UserVerification.user_id == user_id)
        .order_by(desc(UserVerification.created_at), desc(UserVerification.id))
        .limit(1)
    )
    return result.scalar_one_or_none()
