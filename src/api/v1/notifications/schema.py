from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field

from src.utils.response import ResponseModel
from src.models.notifications import NotificationType


class NotificationAction(str, Enum):
    CONFIRM_DELIVERY = "confirm_delivery"
    APPROVE_ADJUSTMENT = "approve_adjustment"
    REJECT_ADJUSTMENT = "reject_adjustment"
    VIEW_ORDER = "view_order"
    OPEN_CHAT = "open_chat"


class NotificationResponse(ResponseModel):
    id: UUID
    type: NotificationType
    title: str = Field(min_length=1, max_length=255)
    body: str
    action_url: str | None = Field(default=None, max_length=500)
    metadata_json: dict[str, object] = Field(default_factory=dict)
    is_read: bool
    is_dismissed: bool
    read_at: datetime | None = None
    dismissed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class NotificationPageResponse(ResponseModel):
    items: list[NotificationResponse] = Field(default_factory=list)
    next_cursor: str | None = None
    has_more: bool = False


class MarkAllReadRequest(BaseModel):
    notification_type: NotificationType | None = None


class NotificationActionRequest(BaseModel):
    action: NotificationAction


class NotificationActionResponse(ResponseModel):
    notification: NotificationResponse
    related_object: dict[str, object] | None = None
