from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from src.models.messaging import ConversationStatus, MessageType
from src.utils.response import ResponseModel


class PeerUserResponse(ResponseModel):
    id: UUID
    full_name: str
    profile_photo_url: str | None = None


class ConversationSummaryResponse(ResponseModel):
    id: UUID
    status: ConversationStatus
    order_id: UUID | None = None
    peer: PeerUserResponse | None = None
    latest_message_preview: str | None = None
    latest_message_at: datetime | None = None
    unread_count: int = 0


class ConversationDetailResponse(ConversationSummaryResponse):
    muted_until: datetime | None = None
    cleared_at: datetime | None = None
    messages: list["MessageResponse"] = Field(default_factory=list)


class ConversationPageResponse(ResponseModel):
    items: list[ConversationSummaryResponse] = Field(default_factory=list)
    count: int = 0
    next_cursor: str | None = None
    has_more: bool = False


class ConversationCreateRequest(BaseModel):
    order_id: UUID | None = None
    participant_user_id: UUID | None = None

    @model_validator(mode="after")
    def validate_target(self) -> ConversationCreateRequest:
        if (self.order_id is None) == (self.participant_user_id is None):
            raise ValueError("Provide exactly one of order_id or participant_user_id.")
        return self


class MessageResponse(ResponseModel):
    id: UUID
    sender_user_id: UUID | None = None
    message_type: MessageType
    body: str
    created_at: datetime


class MessageCreateRequest(BaseModel):
    body: str = Field(min_length=1, max_length=5000)
    message_type: MessageType = MessageType.TEXT


class MessagePageResponse(ResponseModel):
    items: list[MessageResponse] = Field(default_factory=list)
    count: int = 0
    next_cursor: str | None = None
    has_more: bool = False


class MuteConversationRequest(BaseModel):
    muted_until: datetime | None = None


class ConversationMarkReadResponse(ResponseModel):
    conversation_id: UUID
    unread_count: int


class DetailResponse(ResponseModel):
    detail: str


# Update forward references
ConversationDetailResponse.model_rebuild()
