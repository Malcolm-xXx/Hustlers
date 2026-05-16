from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

from src.api.v1.auth.schema import UserSummaryResponse
from src.models.trust import (
    UserReportStatus,
    UserVerificationIDDocumentType,
    UserVerificationStatus,
)
from src.utils.response import ResponseModel


class VerificationStatusResponse(ResponseModel):
    status: UserVerificationStatus
    id_document_type: UserVerificationIDDocumentType | None = None
    id_document_uploaded: bool = False
    face_capture_uploaded: bool = False
    failure_reason: str | None = None
    submitted_at: datetime | None = None
    verified_at: datetime | None = None


class BlockRequest(BaseModel):
    blocked_user_id: uuid.UUID


class BlockResponse(ResponseModel):
    blocked_user: UserSummaryResponse
    created_at: datetime


class BlockPageResponse(ResponseModel):
    items: list[BlockResponse] = Field(default_factory=list)
    next_cursor: str | None = None
    has_more: bool = False


class ReportRequest(BaseModel):
    reported_user_id: uuid.UUID
    order_id: uuid.UUID | None = None
    conversation_id: uuid.UUID | None = None
    reason_type: str = Field(min_length=1, max_length=100)
    details: str = Field(min_length=1, max_length=5000)


class ReportResponse(ResponseModel):
    id: uuid.UUID
    reported_user: UserSummaryResponse
    reason_type: str
    details: str
    status: UserReportStatus
    created_at: datetime


class ReportPageResponse(ResponseModel):
    items: list[ReportResponse] = Field(default_factory=list)
    next_cursor: str | None = None
    has_more: bool = False


class AdminReportDecisionRequest(BaseModel):
    decision: UserReportStatus
    resolution_note: str | None = Field(default=None, max_length=5000)

    @model_validator(mode="after")
    def validate_decision(self) -> "AdminReportDecisionRequest":
        if self.decision == UserReportStatus.PENDING:
            raise ValueError(
                "Invalid decision. Expected one of: reviewed, resolved, dismissed."
            )
        return self


class WebhookPayloadRequest(BaseModel):
    event_id: str | None = Field(default=None, max_length=255)
    status: str | None = Field(default=None, max_length=100)
    payload: dict[str, object]


class WebhookReceivedResponse(ResponseModel):
    received: bool


class VerificationIdDocumentUploadURLRequest(BaseModel):
    """Request to finalize an ID document upload after presigned upload to Cloudinary."""

    id_document_image_url: str
    id_document_image_public_id: str
    id_document_type: UserVerificationIDDocumentType


class VerificationFaceCaptureUploadURLRequest(BaseModel):
    """Request to finalize a face capture upload after presigned upload to Cloudinary."""

    face_capture_image_url: str
    face_capture_image_public_id: str
