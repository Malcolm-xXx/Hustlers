from __future__ import annotations

import asyncio
import uuid
from datetime import datetime, timezone

from fastapi import WebSocket, WebSocketDisconnect, status
from sqlalchemy import and_, desc, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor, get_user_from_access_token
from src.api.v1.notifications.schema import (
    MarkAllReadRequest,
    NotificationAction,
    NotificationActionRequest,
    NotificationActionResponse,
    NotificationPageResponse,
    NotificationResponse,
)
from src.api.v1.notifications.utils import parse_uuid
from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
from src.core.ably import publish_notification
from src.core.exceptions import HTTPException
from src.core.logging import get_logger
from src.models.notifications import Notification, NotificationType
from src.models.orders import OrderItem, OrderItemAdjustment

logger = get_logger(__name__)


def notification_response(notification: Notification) -> NotificationResponse:
    return NotificationResponse(
        id=notification.id,
        type=notification.type,
        title=notification.title,
        body=notification.body,
        action_url=notification.action_url,
        metadata_json=dict(notification.metadata_json or {}),
        is_read=bool(notification.is_read or notification.read_at is not None),
        is_dismissed=bool(
            notification.is_dismissed or notification.dismissed_at is not None
        ),
        read_at=notification.read_at,
        dismissed_at=notification.dismissed_at,
        created_at=notification.created_at,
        updated_at=notification.updated_at,
    )


def notification_cursor(notification: Notification) -> str:
    return encode_cursor(notification.created_at, notification.id)


def notification_socket_payload(notification: Notification) -> dict[str, object]:
    return {
        "type": "notification.created",
        "cursor": notification_cursor(notification),
        "notification": notification_response(notification).model_dump(mode="json"),
    }


def with_cursor_filter(
    statement,
    cursor: str | None,
    *,
    descending: bool,
):
    if not cursor:
        return statement

    cursor_created_at, cursor_id = parse_cursor(cursor)
    if descending:
        return statement.where(
            or_(
                Notification.created_at < cursor_created_at,
                and_(
                    Notification.created_at == cursor_created_at,
                    Notification.id < cursor_id,
                ),
            )
        )

    return statement.where(
        or_(
            Notification.created_at > cursor_created_at,
            and_(
                Notification.created_at == cursor_created_at,
                Notification.id > cursor_id,
            ),
        )
    )


async def list_notifications_page(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    cursor: str | None,
    limit: int,
    unread_only: bool,
    notification_type: NotificationType | None,
) -> tuple[list[Notification], bool]:
    statement = select(Notification).where(Notification.user_id == user_id)
    if unread_only:
        statement = statement.where(Notification.is_read.is_(False))
    if notification_type is not None:
        statement = statement.where(Notification.type == notification_type)

    statement = with_cursor_filter(statement, cursor, descending=True)
    statement = statement.order_by(desc(Notification.created_at), desc(Notification.id))
    statement = statement.limit(limit + 1)

    result = await db.execute(statement)
    notifications = list(result.scalars().all())
    has_more = len(notifications) > limit
    return notifications[:limit], has_more


async def list_notifications_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    notification_type: NotificationType | None = None,
) -> NotificationPageResponse:
    notifications, has_more = await list_notifications_page(
        db,
        user_id=user.id,
        cursor=cursor,
        limit=limit,
        unread_only=False,
        notification_type=notification_type,
    )
    next_cursor = notification_cursor(notifications[-1]) if has_more else None
    return NotificationPageResponse(
        items=[notification_response(notification) for notification in notifications],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def list_unread_notifications_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    notification_type: NotificationType | None = None,
) -> NotificationPageResponse:
    notifications, has_more = await list_notifications_page(
        db,
        user_id=user.id,
        cursor=cursor,
        limit=limit,
        unread_only=True,
        notification_type=notification_type,
    )
    next_cursor = notification_cursor(notifications[-1]) if has_more else None
    return NotificationPageResponse(
        items=[notification_response(notification) for notification in notifications],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def poll_notifications_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    notification_type: NotificationType | None = None,
) -> NotificationPageResponse:
    return await list_notifications_service(
        db,
        user,
        cursor,
        limit,
        notification_type,
    )


async def poll_unread_notifications_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    notification_type: NotificationType | None = None,
) -> NotificationPageResponse:
    return await list_unread_notifications_service(
        db,
        user,
        cursor,
        limit,
        notification_type,
    )


async def get_notification_or_404(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    notification_id: uuid.UUID,
) -> Notification:
    result = await db.execute(
        select(Notification)
        .where(Notification.id == notification_id, Notification.user_id == user_id)
        .limit(1)
    )
    notification = result.scalar_one_or_none()
    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found.",
        )
    return notification


async def mark_all_notifications_read_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: MarkAllReadRequest | None = None,
) -> None:
    now = datetime.now(timezone.utc)
    statement = update(Notification).where(
        Notification.user_id == user.id,
        Notification.is_read.is_(False),
    )
    if request is not None and request.notification_type is not None:
        statement = statement.where(Notification.type == request.notification_type)

    await db.execute(statement.values(is_read=True, read_at=now, updated_at=now))


async def mark_notification_read_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    notification_id: uuid.UUID,
) -> NotificationResponse:
    notification = await get_notification_or_404(
        db,
        user_id=user.id,
        notification_id=notification_id,
    )
    if not notification.is_read or notification.read_at is None:
        now = datetime.now(timezone.utc)
        notification.is_read = True
        notification.read_at = now
        notification.updated_at = now
        db.add(notification)

    return notification_response(notification)


async def dismiss_notification_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    notification_id: uuid.UUID,
) -> NotificationResponse:
    notification = await get_notification_or_404(
        db,
        user_id=user.id,
        notification_id=notification_id,
    )
    now = datetime.now(timezone.utc)
    notification.is_dismissed = True
    notification.dismissed_at = now
    if not notification.is_read or notification.read_at is None:
        notification.is_read = True
        notification.read_at = now
    notification.updated_at = now
    db.add(notification)
    return notification_response(notification)


async def perform_notification_action_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    notification_id: uuid.UUID,
    request: NotificationActionRequest,
) -> NotificationActionResponse:
    notification = await get_notification_or_404(
        db,
        user_id=user.id,
        notification_id=notification_id,
    )

    related_object: dict[str, object] | None = None
    metadata = notification.metadata_json or {}

    if request.action == NotificationAction.CONFIRM_DELIVERY:
        order_id_str = metadata.get("order_id")
        order_id = parse_uuid(str(order_id_str)) if order_id_str else None
        if order_id is not None:
            from src.models.orders import Order, OrderStatus

            result = await db.execute(
                select(Order)
                .where(Order.id == order_id, Order.buyer_id == user.id)
                .limit(1)
            )
            order = result.scalar_one_or_none()
            if order is not None:
                now = datetime.now(timezone.utc)
                order.buyer_confirmed_delivered_at = now
                order.status = OrderStatus.DONE
                order.updated_at = now
                db.add(order)
                related_object = {
                    "order_id": str(order.id),
                    "status": order.status.value,
                }

    elif request.action in {
        NotificationAction.APPROVE_ADJUSTMENT,
        NotificationAction.REJECT_ADJUSTMENT,
    }:
        adjustment_id_str = metadata.get("adjustment_id")
        adjustment_id = (
            parse_uuid(str(adjustment_id_str)) if adjustment_id_str else None
        )
        if adjustment_id is not None:
            from src.api.v1.orders.schema import (
                AdjustmentDecisionRequest,
                OrderDecision,
            )
            from src.api.v1.orders.service import decide_adjustment_service

            adjustment_decision = (
                OrderDecision.APPROVE
                if request.action == NotificationAction.APPROVE_ADJUSTMENT
                else OrderDecision.REJECT
            )
            decision_request = AdjustmentDecisionRequest(decision=adjustment_decision)

            adjustment_result = await db.execute(
                select(OrderItemAdjustment)
                .where(OrderItemAdjustment.id == adjustment_id)
                .limit(1)
            )
            adjustment = adjustment_result.scalar_one_or_none()
            if adjustment is not None:
                order_item_result = await db.execute(
                    select(OrderItem)
                    .where(OrderItem.id == adjustment.order_item_id)
                    .limit(1)
                )
                order_item = order_item_result.scalar_one_or_none()
                if order_item is None:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Order item for adjustment not found.",
                    )
                await decide_adjustment_service(
                    db,
                    user,
                    order_item.order_id,
                    adjustment.id,
                    decision_request,
                )
                related_object = {
                    "order_id": str(order_item.order_id),
                    "adjustment_id": str(adjustment.id),
                    "decision": adjustment_decision.value,
                }

    elif request.action == NotificationAction.VIEW_ORDER:
        order_id_str = metadata.get("order_id")
        order_id = parse_uuid(str(order_id_str)) if order_id_str else None
        if order_id is not None:
            related_object = {"order_id": str(order_id)}

    elif request.action == NotificationAction.OPEN_CHAT:
        conversation_id_str = metadata.get("conversation_id")
        conversation_id = (
            parse_uuid(str(conversation_id_str)) if conversation_id_str else None
        )
        if conversation_id is not None:
            related_object = {"conversation_id": str(conversation_id)}

    now = datetime.now(timezone.utc)
    if not notification.is_read or notification.read_at is None:
        notification.is_read = True
        notification.read_at = now
    notification.updated_at = now
    db.add(notification)

    return NotificationActionResponse(
        notification=notification_response(notification),
        related_object=related_object,
    )


async def websocket_notifications(
    db: AsyncSession,
    websocket: WebSocket,
    token: str | None,
    cursor: str | None,
    notification_type: NotificationType | None = None,
    poll_interval: float = 2.0,
) -> None:
    if token is None or not token.strip():
        await websocket.close(
            code=status.WS_1008_POLICY_VIOLATION, reason="Not authenticated"
        )
        return

    try:
        user = await get_user_from_access_token(db, token.strip())
        if cursor is not None:
            parse_cursor(cursor)
    except HTTPException as exc:
        await websocket.close(
            code=status.WS_1008_POLICY_VIOLATION,
            reason=str(exc.detail),
        )
        return

    await websocket.accept()
    last_seen = (
        parse_cursor(cursor)
        if cursor is not None
        else (datetime.now(timezone.utc), uuid.UUID(int=0))
    )

    try:
        await websocket.send_json(
            {
                "type": "notification.connected",
                "cursor": cursor,
                "notification_type": (
                    notification_type.value if notification_type is not None else None
                ),
            }
        )

        while True:
            statement = select(Notification).where(Notification.user_id == user.id)
            if notification_type is not None:
                statement = statement.where(Notification.type == notification_type)
            statement = statement.where(
                or_(
                    Notification.created_at > last_seen[0],
                    and_(
                        Notification.created_at == last_seen[0],
                        Notification.id > last_seen[1],
                    ),
                )
            )
            statement = statement.order_by(
                Notification.created_at.asc(), Notification.id.asc()
            )
            statement = statement.limit(100)

            result = await db.execute(statement)
            notifications = list(result.scalars().all())
            if notifications:
                for notification in notifications:
                    last_seen = (notification.created_at, notification.id)
                    await websocket.send_json(notification_socket_payload(notification))
                continue

            try:
                payload = await asyncio.wait_for(
                    websocket.receive_json(), timeout=poll_interval
                )
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "notification.ping"})
                continue
            except WebSocketDisconnect:
                return

            event_type = str(payload.get("type") or "").strip().lower()
            if event_type == "ping":
                await websocket.send_json({"type": "notification.pong"})
                continue

            if event_type == "sync":
                new_cursor = str(payload.get("cursor") or "").strip()
                if not new_cursor:
                    await websocket.send_json(
                        {
                            "type": "notification.error",
                            "detail": "cursor is required.",
                        }
                    )
                    continue
                try:
                    last_seen = parse_cursor(new_cursor)
                except HTTPException as exc:
                    await websocket.send_json(
                        {"type": "notification.error", "detail": exc.detail}
                    )
                    continue
                await websocket.send_json(
                    {"type": "notification.synced", "cursor": new_cursor}
                )
                continue

            await websocket.send_json(
                {
                    "type": "notification.error",
                    "detail": "Unsupported websocket event.",
                }
            )
    except WebSocketDisconnect:
        return


async def websocket_notifications_service(
    db: AsyncSession,
    websocket: WebSocket,
    token: str | None,
    cursor: str | None,
    notification_type: NotificationType | None = None,
    poll_interval: float = 2.0,
) -> None:
    await websocket_notifications(
        db,
        websocket,
        token,
        cursor,
        notification_type,
        poll_interval,
    )


async def send_notification(
    db: AsyncSession,
    user_id: uuid.UUID,
    notification_type: NotificationType,
    title: str,
    body: str,
    action_url: str | None = None,
    metadata_json: dict[str, object] | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        type=notification_type,
        title=title,
        body=body,
        action_url=action_url,
        metadata_json=metadata_json or {},
    )
    db.add(notification)
    await db.flush()
    await db.refresh(notification)

    await publish_notification(
        user_id=user_id,
        title=title,
        body=body,
        data={"type": notification_type.value, **(metadata_json or {})},
        notification_id=notification.id,
    )
    logger.info(
        "notification_sent",
        notification_id=str(notification.id),
        user_id=str(user_id),
        notification_type=notification_type.value,
    )

    return notification
