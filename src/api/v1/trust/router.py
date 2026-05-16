import uuid

from fastapi import APIRouter, Depends, Query, Request

from src.api.v1.shared.schema import PresignedUploadURLResponse
from src.api.v1.trust.schema import (
    AdminReportDecisionRequest,
    BlockPageResponse,
    BlockRequest,
    BlockResponse,
    ReportPageResponse,
    ReportRequest,
    ReportResponse,
    VerificationFaceCaptureUploadURLRequest,
    VerificationIdDocumentUploadURLRequest,
    VerificationStatusResponse,
    WebhookReceivedResponse,
)
from src.api.v1.trust.service import (
    admin_decide_report_service,
    create_block_service,
    create_report_service,
    delete_block_service,
    generate_face_capture_upload_url_service,
    generate_id_document_upload_url_service,
    get_verification_status_service,
    list_admin_reports_service,
    list_blocks_service,
    list_my_reports_service,
    submit_verification_service,
    upload_verification_face_capture_from_url_service,
    upload_verification_id_document_from_url_service,
    verification_provider_webhook_service,
)
from src.models.auth import User
from src.utils.dependencies import AuthenticatedContext, DbSession
from src.utils.permissions import get_admin_user

router = APIRouter()


@router.get("/verification/", response_model=VerificationStatusResponse)
async def get_verification_status(auth_context: AuthenticatedContext):
    return await get_verification_status_service(auth_context.db, auth_context.user)


@router.get(
    "/verification/id-document/upload-url/", response_model=PresignedUploadURLResponse
)
async def get_id_document_upload_url(auth_context: AuthenticatedContext):
    return await generate_id_document_upload_url_service(
        auth_context.db, auth_context.user
    )


@router.get(
    "/verification/face-capture/upload-url/", response_model=PresignedUploadURLResponse
)
async def get_face_capture_upload_url(auth_context: AuthenticatedContext):
    return await generate_face_capture_upload_url_service(
        auth_context.db, auth_context.user
    )


@router.post(
    "/verification/id-document-from-url/", response_model=VerificationStatusResponse
)
async def upload_id_document_from_url(
    request_data: VerificationIdDocumentUploadURLRequest,
    auth_context: AuthenticatedContext,
):
    return await upload_verification_id_document_from_url_service(
        auth_context.db,
        auth_context.user,
        request_data.id_document_image_url,
        request_data.id_document_image_public_id,
        request_data.id_document_type,
    )


@router.post(
    "/verification/face-capture-from-url/", response_model=VerificationStatusResponse
)
async def upload_face_capture_from_url(
    request_data: VerificationFaceCaptureUploadURLRequest,
    auth_context: AuthenticatedContext,
):
    return await upload_verification_face_capture_from_url_service(
        auth_context.db,
        auth_context.user,
        request_data.face_capture_image_url,
        request_data.face_capture_image_public_id,
    )


@router.post("/verification/submit/", response_model=VerificationStatusResponse)
async def submit_verification(
    auth_context: AuthenticatedContext,
):
    return await submit_verification_service(auth_context.db, auth_context.user)


@router.get("/blocks/", response_model=BlockPageResponse)
async def list_blocks(
    auth_context: AuthenticatedContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_blocks_service(auth_context.db, auth_context.user, cursor, limit)


@router.post("/blocks/", response_model=BlockResponse, status_code=201)
async def create_block(
    request: BlockRequest,
    auth_context: AuthenticatedContext,
):
    return await create_block_service(auth_context.db, auth_context.user, request)


@router.delete("/blocks/{blocked_user_id}/", status_code=204)
async def delete_block(
    blocked_user_id: uuid.UUID,
    auth_context: AuthenticatedContext,
):
    await delete_block_service(auth_context.db, auth_context.user, blocked_user_id)


@router.get("/reports/me/", response_model=ReportPageResponse)
async def list_my_reports(
    auth_context: AuthenticatedContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_my_reports_service(
        auth_context.db, auth_context.user, cursor, limit
    )


@router.post("/reports/", response_model=ReportResponse, status_code=201)
async def create_report(
    request: ReportRequest,
    auth_context: AuthenticatedContext,
):
    return await create_report_service(auth_context.db, auth_context.user, request)


@router.get("/admin/reports/", response_model=ReportPageResponse)
async def list_admin_reports(
    db: DbSession,
    user: User = Depends(get_admin_user),
    status: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_admin_reports_service(db, user, status, cursor, limit)


@router.post("/admin/reports/{report_id}/decision/", response_model=ReportResponse)
async def admin_decide_report(
    report_id: uuid.UUID,
    db: DbSession,
    request: AdminReportDecisionRequest,
    user: User = Depends(get_admin_user),
):
    return await admin_decide_report_service(db, user, report_id, request)


@router.post("/webhooks/verification-provider/", response_model=WebhookReceivedResponse)
async def verification_provider_webhook(
    request: Request,
    db: DbSession,
):
    return await verification_provider_webhook_service(db, request)
