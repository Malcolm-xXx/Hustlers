import uuid

from fastapi import APIRouter, Query, WebSocket

from src.models.notifications import NotificationType
from src.api.v1.notifications.schema import (
    MarkAllReadRequest,
    NotificationActionRequest,
    NotificationActionResponse,
    NotificationPageResponse,
    NotificationResponse,
)
from src.api.v1.notifications.service import (
    dismiss_notification_service,
    list_notifications_service,
    list_unread_notifications_service,
    mark_all_notifications_read_service,
    mark_notification_read_service,
    perform_notification_action_service,
    poll_notifications_service,
    poll_unread_notifications_service,
    websocket_notifications_service,
)
from src.utils.dependencies import AuthenticatedActorContext, DbSession

router = APIRouter()


@router.get("/", response_model=NotificationPageResponse)
async def list_notifications(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    notification_type: NotificationType | None = Query(default=None),
):
    return await list_notifications_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        notification_type,
    )


@router.get("/unread/", response_model=NotificationPageResponse)
async def list_unread_notifications(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    notification_type: NotificationType | None = Query(default=None),
):
    return await list_unread_notifications_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        notification_type,
    )


@router.get("/poll/", response_model=NotificationPageResponse)
async def poll_notifications(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    notification_type: NotificationType | None = Query(default=None),
):
    return await poll_notifications_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        notification_type,
    )


@router.get("/poll/unread/", response_model=NotificationPageResponse)
async def poll_unread_notifications(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    notification_type: NotificationType | None = Query(default=None),
):
    return await poll_unread_notifications_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        notification_type,
    )


@router.post("/mark-all-read/", status_code=204)
async def mark_all_notifications_read(
    auth_context: AuthenticatedActorContext,
    request: MarkAllReadRequest | None = None,
):
    await mark_all_notifications_read_service(
        auth_context.db, auth_context.user, request
    )


@router.post("/{notification_id}/read/", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: uuid.UUID,
    auth_context: AuthenticatedActorContext,
):
    return await mark_notification_read_service(
        auth_context.db,
        auth_context.user,
        notification_id,
    )


@router.delete("/{notification_id}/dismiss/", response_model=NotificationResponse)
async def dismiss_notification(
    notification_id: uuid.UUID,
    auth_context: AuthenticatedActorContext,
):
    return await dismiss_notification_service(
        auth_context.db,
        auth_context.user,
        notification_id,
    )


@router.post("/{notification_id}/action/", response_model=NotificationActionResponse)
async def perform_notification_action(
    notification_id: uuid.UUID,
    request: NotificationActionRequest,
    auth_context: AuthenticatedActorContext,
):
    return await perform_notification_action_service(
        auth_context.db,
        auth_context.user,
        notification_id,
        request,
    )


@router.websocket("/ws/")
async def notifications_websocket(
    websocket: WebSocket,
    db: DbSession,
    token: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    notification_type: NotificationType | None = Query(default=None),
):
    await websocket_notifications_service(
        db,
        websocket,
        token,
        cursor,
        notification_type,
    )
