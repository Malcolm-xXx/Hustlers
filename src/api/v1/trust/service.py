import json
import uuid
from datetime import datetime, timezone

from fastapi import Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.trust.queries import (
    delete_block,
    get_admin_reports,
    get_block_by_id,
    get_block,
    get_blocks_by_user,
    get_report_by_id,
    get_report_for_update,
    get_reports_by_user,
    get_verification_by_provider_reference,
)
from src.api.v1.trust.utils import get_or_create_verification
from src.api.v1.trust.schema import (
    AdminReportDecisionRequest,
    BlockPageResponse,
    BlockRequest,
    BlockResponse,
    ReportPageResponse,
    ReportRequest,
    ReportResponse,
    VerificationStatusResponse,
    WebhookReceivedResponse,
)
from src.api.v1.trust.utils import (
    activate_seller_from_verification,
    apply_webhook_event,
    ensure_conversation_is_reportable,
    ensure_non_self_target,
    ensure_order_is_reportable,
    ensure_user_exists,
    encode_timestamp_cursor,
    get_verification_provider,
    infer_verification_provider_name,
    serialize_block,
    serialize_report,
    verification_response,
)
from src.core.exceptions import HTTPException
from src.models.auth import User
from src.models.trust import UserBlock, UserReportStatus
from src.utils.images import get_image_provider


async def get_verification_status_service(
    db: AsyncSession,
    user: User,
) -> VerificationStatusResponse:
    verification = await get_or_create_verification(db, user)
    return verification_response(verification)


async def generate_id_document_upload_url_service(
    db: AsyncSession,
    user: User,
) -> dict:
    verification = await get_or_create_verification(db, user)

    provider = get_image_provider()
    presigned_response = await provider.generate_presigned_url(
        folder=f"trust/verification/{verification.id}",
        file_type="id_document",
        resource_type="image",
        expiration_minutes=15,
    )

    return {
        "upload_url": presigned_response.upload_url,
        "public_id": presigned_response.public_id,
        "signature": presigned_response.signature,
        "api_key": presigned_response.api_key,
        "timestamp": presigned_response.timestamp,
        "expires_in": presigned_response.expires_in,
        "allowed_types": presigned_response.allowed_types,
    }


async def generate_face_capture_upload_url_service(
    db: AsyncSession,
    user: User,
) -> dict:
    verification = await get_or_create_verification(db, user)

    provider = get_image_provider()
    presigned_response = await provider.generate_presigned_url(
        folder=f"trust/verification/{verification.id}",
        file_type="face_capture",
        resource_type="image",
        expiration_minutes=15,
    )

    return {
        "upload_url": presigned_response.upload_url,
        "public_id": presigned_response.public_id,
        "signature": presigned_response.signature,
        "api_key": presigned_response.api_key,
        "timestamp": presigned_response.timestamp,
        "expires_in": presigned_response.expires_in,
        "allowed_types": presigned_response.allowed_types,
    }


async def upload_verification_id_document_from_url_service(
    db: AsyncSession,
    user: User,
    image_url: str,
    public_id: str,
    id_document_type,
) -> VerificationStatusResponse:
    from src.models.trust import UserVerificationStatus

    verification = await get_or_create_verification(db, user)

    if not image_url or not public_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="image_url and public_id are required",
        )

    verification.id_document_type = id_document_type
    verification.id_document_image_url = image_url
    verification.id_document_image_cloudinary_public_id = public_id
    verification.failure_reason = ""
    verification.status = UserVerificationStatus.NOT_STARTED
    verification.verified_at = None
    await db.flush()
    return verification_response(verification)


async def upload_verification_face_capture_from_url_service(
    db: AsyncSession,
    user: User,
    image_url: str,
    public_id: str,
) -> VerificationStatusResponse:
    from src.models.trust import UserVerificationStatus

    verification = await get_or_create_verification(db, user)

    if not image_url or not public_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="image_url and public_id are required",
        )

    verification.face_capture_image_url = image_url
    verification.face_capture_image_cloudinary_public_id = public_id
    verification.failure_reason = ""
    verification.status = UserVerificationStatus.NOT_STARTED
    verification.verified_at = None
    await db.flush()
    return verification_response(verification)


async def submit_verification_service(
    db: AsyncSession,
    user: User,
) -> VerificationStatusResponse:
    from src.models.trust import UserVerificationStatus

    verification = await get_or_create_verification(db, user)
    if not verification.id_document_image_url:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"id_document_image": ["Upload an ID document before submission."]},
        )
    if not verification.face_capture_image_url:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"face_capture_image": ["Upload a face capture before submission."]},
        )

    provider = get_verification_provider(None)
    result = provider.submit_verification(verification)

    verification.provider_name = provider.provider_name
    verification.provider_reference = result.provider_reference
    verification.provider_payload_json = result.payload
    verification.status = UserVerificationStatus(result.status.value)
    verification.submitted_at = datetime.now(timezone.utc)

    if result.status == UserVerificationStatus.VERIFIED:
        verification.verified_at = datetime.now(timezone.utc)
        verification.failure_reason = ""
    elif result.status == UserVerificationStatus.FAILED:
        verification.verified_at = None
        verification.failure_reason = result.failure_reason
    else:
        verification.verified_at = None
        verification.failure_reason = ""

    await activate_seller_from_verification(db, user, result.status)
    await db.flush()
    return verification_response(verification)


async def list_blocks_service(
    db: AsyncSession,
    user: User,
    cursor: str | None,
    limit: int,
) -> BlockPageResponse:
    blocks, has_more = await get_blocks_by_user(db, user.id, cursor, limit)

    next_cursor = None
    if has_more and blocks:
        tail_item = blocks[-1]
        next_cursor = encode_timestamp_cursor(tail_item.created_at, tail_item.id)

    return BlockPageResponse(
        items=[serialize_block(block) for block in blocks],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def create_block_service(
    db: AsyncSession,
    user: User,
    request: BlockRequest,
) -> BlockResponse:
    blocked_user_id = uuid.UUID(str(request.blocked_user_id))
    ensure_non_self_target(
        blocked_user_id,
        user.id,
        field_name="blocked_user_id",
        message="You cannot block yourself.",
    )
    await ensure_user_exists(
        db,
        blocked_user_id,
        "blocked_user_id",
        "Blocked user not found.",
    )

    block = await get_block(db, user.id, blocked_user_id)
    if block is None:
        new_block = UserBlock(blocker_user_id=user.id, blocked_user_id=blocked_user_id)
        db.add(new_block)
        await db.flush()
        block = await get_block_by_id(db, new_block.id)

    if block is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Block not found.")
    return serialize_block(block)


async def delete_block_service(
    db: AsyncSession,
    user: User,
    blocked_user_id: uuid.UUID,
) -> None:
    await delete_block(db, user.id, blocked_user_id)


async def list_my_reports_service(
    db: AsyncSession,
    user: User,
    cursor: str | None,
    limit: int,
) -> ReportPageResponse:
    reports, has_more = await get_reports_by_user(db, user.id, cursor, limit)

    next_cursor = None
    if has_more and reports:
        tail_item = reports[-1]
        next_cursor = encode_timestamp_cursor(tail_item.created_at, tail_item.id)

    return ReportPageResponse(
        items=[serialize_report(report) for report in reports],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def create_report_service(
    db: AsyncSession,
    user: User,
    request: ReportRequest,
) -> ReportResponse:
    from src.models.trust import UserReport

    reported_user_id = uuid.UUID(str(request.reported_user_id))
    ensure_non_self_target(
        reported_user_id,
        user.id,
        field_name="reported_user_id",
        message="You cannot report yourself.",
    )
    await ensure_user_exists(
        db,
        reported_user_id,
        "reported_user_id",
        "Reported user not found.",
    )

    order_id = uuid.UUID(str(request.order_id)) if request.order_id else None
    conversation_id = (
        uuid.UUID(str(request.conversation_id)) if request.conversation_id else None
    )

    if order_id is not None:
        await ensure_order_is_reportable(db, user.id, order_id)

    if conversation_id is not None:
        await ensure_conversation_is_reportable(db, user.id, conversation_id)

    report = UserReport(
        reporter_user_id=user.id,
        reported_user_id=reported_user_id,
        order_id=order_id,
        conversation_id=conversation_id,
        reason_type=request.reason_type,
        details=request.details,
    )
    db.add(report)
    await db.flush()

    result = await get_report_by_id(db, report.id)
    if result is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Report not found.")
    return serialize_report(result)


async def list_admin_reports_service(
    db: AsyncSession,
    user: User,
    status_filter: str | None,
    cursor: str | None,
    limit: int,
) -> ReportPageResponse:
    reports, has_more = await get_admin_reports(db, status_filter, cursor, limit)

    next_cursor = None
    if has_more and reports:
        tail_item = reports[-1]
        next_cursor = encode_timestamp_cursor(tail_item.created_at, tail_item.id)

    return ReportPageResponse(
        items=[serialize_report(report) for report in reports],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def admin_decide_report_service(
    db: AsyncSession,
    user: User,
    report_id: uuid.UUID,
    request: AdminReportDecisionRequest,
) -> ReportResponse:
    report = await get_report_for_update(db, report_id)
    if report is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Report not found.")

    decision = request.decision.value
    report.status = UserReportStatus(decision)
    report.resolution_note = request.resolution_note or ""
    report.resolved_by_user_id = user.id
    if report.status in {UserReportStatus.RESOLVED, UserReportStatus.DISMISSED}:
        report.resolved_at = datetime.now(timezone.utc)
    else:
        report.resolved_at = None

    await db.flush()
    return serialize_report(report)


async def verification_provider_webhook_service(
    db: AsyncSession,
    request: Request,
) -> WebhookReceivedResponse:
    raw_body = await request.body()
    try:
        payload = json.loads(raw_body.decode("utf-8") or "{}")
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload."
        ) from exc

    if not isinstance(payload, dict):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Invalid JSON payload.")

    provider_name = infer_verification_provider_name(
        headers=request.headers,
        explicit_provider_name=request.query_params.get("provider_name"),
    )
    provider = get_verification_provider(provider_name)

    if not provider.verify_webhook_signature(raw_body, request.headers):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid webhook signature."
        )

    event = provider.parse_webhook_event(payload)
    if event is None or not event.provider_reference:
        return WebhookReceivedResponse(received=True)

    verification = await get_verification_by_provider_reference(
        db, event.provider_reference, provider.provider_name
    )

    if verification is None:
        return WebhookReceivedResponse(received=True)

    if apply_webhook_event(verification, event):
        await activate_seller_from_verification(db, verification.user, event.status)
        await db.flush()

    return WebhookReceivedResponse(received=True)
