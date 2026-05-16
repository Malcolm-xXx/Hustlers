from __future__ import annotations

import json
import time
from typing import TYPE_CHECKING, Any

import structlog
from ably import AblyRest
from jose import jwt as jose_jwt

from src.core.config import settings

if TYPE_CHECKING:
    from uuid import UUID

logger = structlog.get_logger(__name__)

_ably_client: AblyRest | None = None


def get_ably_client() -> AblyRest:
    if _ably_client is None:
        msg = "Ably client not initialized"
        raise RuntimeError(msg)
    return _ably_client


def create_ably_jwt(
    *,
    client_id: str,
    capability: dict[str, list[str]],
    expires_in: int = 3600,
) -> str:
    api_key = settings.ABLY_SUBSCRIBE_KEY
    key_name, key_secret = api_key.split(":")
    now = int(time.time())
    payload = {
        "x-ably-capability": json.dumps(capability),
        "x-ably-clientId": client_id,
        "iat": now,
        "exp": now + expires_in,
    }
    token = jose_jwt.encode(
        payload, key_secret, algorithm="HS256", headers={"kid": key_name}
    )
    return token


async def publish_to_channel(
    channel_name: str,
    event_name: str,
    data: dict[str, Any],
    *,
    push: dict[str, Any] | None = None,
) -> None:
    client = get_ably_client()
    payload: dict[str, Any] = {"name": event_name, "data": data}
    if push is not None:
        payload["extras"] = {"push": push}
    try:
        await client.channels.get(channel_name).publish(payload)
    except Exception:
        logger.exception(
            "Failed to publish to Ably channel",
            channel=channel_name,
            event=event_name,
        )
        raise


async def publish_notification(
    *,
    user_id: UUID,
    title: str,
    body: str,
    data: dict[str, object],
    notification_id: UUID,
) -> None:
    channel_name = f"notifications:user-{user_id}"
    push_payload = {
        "notification": {
            "title": title,
            "body": body,
        },
        "data": {
            "notification_id": str(notification_id),
            **data,
        },
    }
    channel_data = {
        "notification_id": str(notification_id),
        "title": title,
        "body": body,
        **data,
    }
    await publish_to_channel(
        channel_name,
        "notification",
        channel_data,
        push=push_payload,
    )


async def publish_message(
    *,
    conversation_id: UUID,
    event_type: str,
    conversation_data: dict[str, object],
    message_data: dict[str, object] | None = None,
) -> None:
    channel_name = f"messaging:conversation-{conversation_id}"
    data: dict[str, object] = {
        "type": event_type,
        "conversation": conversation_data,
    }
    if message_data is not None:
        data["message"] = message_data
    await publish_to_channel(channel_name, event_type, data)


async def publish_conversation_update(
    *,
    conversation_id: UUID,
    unread_count: int,
) -> None:
    channel_name = f"messaging:conversation-{conversation_id}"
    data: dict[str, object] = {
        "type": "conversation.updated",
        "conversation_id": str(conversation_id),
        "unread_count": unread_count,
    }
    await publish_to_channel(channel_name, "conversation.updated", data)
