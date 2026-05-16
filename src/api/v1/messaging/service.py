from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import status
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.messaging.schema import (
    ConversationCreateRequest,
    ConversationDetailResponse,
    ConversationMarkReadResponse,
    ConversationPageResponse,
    ConversationStatus,
    ConversationSummaryResponse,
    DetailResponse,
    MessageCreateRequest,
    MessagePageResponse,
    MessageResponse,
    MessageType,
    MuteConversationRequest,
    PeerUserResponse,
)
from src.api.v1.shared.utils.encoding import encode_cursor, parse_cursor
from src.core.ably import publish_conversation_update, publish_message
from src.core.exceptions import HTTPException
from src.core.logging import get_logger
from src.models.auth import User
from src.models.messaging import (
    Conversation,
    ConversationMember,
    Message,
)
from src.models.messaging import (
    ConversationStatus as ConversationStatusModel,
)
from src.models.messaging import (
    ConversationType as ConversationTypeModel,
)
from src.models.messaging import (
    MessageType as MessageTypeModel,
)
from src.models.orders import Order
from src.models.sellers import SellerProfile

logger = get_logger(__name__)


connection_manager = None


def conversation_sort_timestamp(conversation: Conversation) -> datetime:
    return conversation.last_message_at or conversation.created_at


def conversation_member_for_user(
    conversation: Conversation, user_id: uuid.UUID
) -> ConversationMember | None:
    return next(
        (member for member in conversation.members if member.user_id == user_id), None
    )


def peer_member_for_user(
    conversation: Conversation, user_id: uuid.UUID
) -> ConversationMember | None:
    return next(
        (member for member in conversation.members if member.user_id != user_id), None
    )


def peer_user_response(member: ConversationMember | None) -> PeerUserResponse | None:
    if member is None:
        return None
    user = member.user
    return PeerUserResponse(
        id=user.id,
        full_name=user.full_name,
        profile_photo_url=user.profile_photo_url,
    )


def message_response(message: Message) -> MessageResponse:
    return MessageResponse(
        id=message.id,
        sender_user_id=message.sender_user_id,
        message_type=MessageType(message.message_type.value),
        body=message.body,
        created_at=message.created_at,
    )


def conversation_summary_response(
    conversation: Conversation,
    viewer_user_id: uuid.UUID,
) -> ConversationSummaryResponse:
    member = conversation_member_for_user(conversation, viewer_user_id)
    return ConversationSummaryResponse(
        id=conversation.id,
        status=ConversationStatus(conversation.status.value),
        order_id=conversation.order_id,
        peer=peer_user_response(peer_member_for_user(conversation, viewer_user_id)),
        latest_message_preview=conversation.last_message_preview or None,
        latest_message_at=conversation.last_message_at,
        unread_count=member.unread_count_cached if member is not None else 0,
    )


def conversation_detail_response(
    conversation: Conversation,
    viewer_user_id: uuid.UUID,
    messages: list[Message],
) -> ConversationDetailResponse:
    member = conversation_member_for_user(conversation, viewer_user_id)
    summary = conversation_summary_response(conversation, viewer_user_id)
    return ConversationDetailResponse(
        **summary.model_dump(),
        muted_until=member.muted_until if member is not None else None,
        cleared_at=member.cleared_at if member is not None else None,
        messages=[message_response(message) for message in messages],
    )


def conversation_event_payload(
    conversation: Conversation,
    viewer_user_id: uuid.UUID,
    *,
    event_type: str,
    message: Message | None = None,
) -> dict[str, object]:
    payload: dict[str, object] = {
        "type": event_type,
        "conversation": conversation_summary_response(
            conversation, viewer_user_id
        ).model_dump(mode="json"),
    }
    if message is not None:
        payload["message"] = message_response(message).model_dump(mode="json")
    return payload


async def conversation_for_user_or_404(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    conversation_id: uuid.UUID,
) -> Conversation:
    statement = (
        select(Conversation)
        .options(
            selectinload(Conversation.members).selectinload(ConversationMember.user),
            selectinload(Conversation.order),
        )
        .where(
            Conversation.id == conversation_id,
            Conversation.members.any(ConversationMember.user_id == user_id),
        )
    )
    result = await db.execute(statement)
    conversation = result.scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Conversation not found.")
    return conversation


async def conversation_messages(
    db: AsyncSession,
    *,
    conversation_id: uuid.UUID,
    cursor: str | None,
    limit: int,
) -> MessagePageResponse:
    safe_limit = min(max(limit, 1), 100)
    count_result = await db.execute(
        select(func.count())
        .select_from(Message)
        .where(Message.conversation_id == conversation_id)
    )
    total_count = int(count_result.scalar_one())

    timestamp_column = Message.created_at
    statement = (
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(desc(Message.created_at), desc(Message.id))
    )
    if cursor is not None:
        cursor_created_at, cursor_id = parse_cursor(cursor)
        statement = statement.where(
            or_(
                timestamp_column < cursor_created_at,
                and_(timestamp_column == cursor_created_at, Message.id < cursor_id),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    messages = list(result.scalars().all())
    has_more = len(messages) > safe_limit
    messages = messages[:safe_limit]

    if not messages:
        return MessagePageResponse(
            items=[], count=total_count, next_cursor=None, has_more=False
        )

    next_cursor = (
        encode_cursor(messages[-1].created_at, messages[-1].id) if has_more else None
    )
    return MessagePageResponse(
        items=[message_response(message) for message in messages],
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def conversation_detail_messages(
    db: AsyncSession,
    *,
    conversation_id: uuid.UUID,
) -> list[Message]:
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc(), Message.id.asc())
        .limit(100)
    )
    return list(result.scalars().all())


async def conversation_detail_for_user(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    conversation_id: uuid.UUID,
) -> ConversationDetailResponse:
    conversation = await conversation_for_user_or_404(
        db,
        user_id=user_id,
        conversation_id=conversation_id,
    )
    messages = await conversation_detail_messages(db, conversation_id=conversation.id)
    return conversation_detail_response(conversation, user_id, messages)


async def conversation_page(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    cursor: str | None,
    limit: int,
    status_filter: str | None,
    search: str | None,
) -> ConversationPageResponse:
    safe_limit = min(max(limit, 1), 100)
    filters = [Conversation.members.any(ConversationMember.user_id == user_id)]

    parsed_status = None
    if status_filter is not None:
        normalized_status = status_filter.strip().lower()
        if normalized_status:
            try:
                parsed_status = ConversationStatusModel(normalized_status)
            except ValueError as exc:
                raise HTTPException(
                    status.HTTP_400_BAD_REQUEST,
                    detail="Invalid status. Expected active or resolved.",
                ) from exc
            filters.append(Conversation.status == parsed_status)

    if search:
        search_term = f"%{search.strip()}%"
        if search_term != "%%":
            filters.append(
                or_(
                    Conversation.last_message_preview.ilike(search_term),
                    Conversation.members.any(
                        ConversationMember.user.has(User.full_name.ilike(search_term))
                    ),
                    Conversation.order.has(Order.order_number.ilike(search_term)),
                )
            )

    count_result = await db.execute(
        select(func.count()).select_from(Conversation).where(*filters)
    )
    total_count = int(count_result.scalar_one())

    sort_timestamp = func.coalesce(
        Conversation.last_message_at, Conversation.created_at
    )
    statement = (
        select(Conversation)
        .options(
            selectinload(Conversation.members).selectinload(ConversationMember.user),
            selectinload(Conversation.order),
        )
        .where(*filters)
        .order_by(desc(sort_timestamp), desc(Conversation.id))
    )
    if cursor is not None:
        cursor_created_at, cursor_id = parse_cursor(cursor)
        statement = statement.where(
            or_(
                sort_timestamp < cursor_created_at,
                and_(sort_timestamp == cursor_created_at, Conversation.id < cursor_id),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    conversations = list(result.scalars().unique().all())
    has_more = len(conversations) > safe_limit
    conversations = conversations[:safe_limit]

    if not conversations:
        return ConversationPageResponse(
            items=[], count=total_count, next_cursor=None, has_more=False
        )

    next_cursor = (
        encode_cursor(
            conversation_sort_timestamp(conversations[-1]), conversations[-1].id
        )
        if has_more
        else None
    )
    return ConversationPageResponse(
        items=[
            conversation_summary_response(conversation, user_id)
            for conversation in conversations
        ],
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def ensure_order_conversation(
    db: AsyncSession,
    *,
    order_id: uuid.UUID,
    user_id: uuid.UUID,
) -> Conversation:
    order_result = await db.execute(select(Order).where(Order.id == order_id))
    order = order_result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order not found.")

    seller_result = await db.execute(
        select(SellerProfile).where(SellerProfile.id == order.seller_id)
    )
    seller = seller_result.scalar_one_or_none()
    if seller is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order seller not found.")

    if user_id not in {order.buyer_id, seller.user_id}:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail="You are not a participant in this order.",
        )

    statement = (
        select(Conversation)
        .options(
            selectinload(Conversation.members).selectinload(ConversationMember.user),
            selectinload(Conversation.order),
        )
        .where(Conversation.order_id == order.id)
        .limit(1)
    )
    existing_result = await db.execute(statement)
    conversation = existing_result.scalar_one_or_none()
    if conversation is None:
        conversation = Conversation(
            conversation_type=ConversationTypeModel.ORDER,
            order_id=order.id,
            status=ConversationStatusModel.ACTIVE,
        )
        db.add(conversation)
        conversation.members.append(ConversationMember(user_id=order.buyer_id))
        conversation.members.append(ConversationMember(user_id=seller.user_id))
        await db.flush()
        return conversation

    existing_member_ids = {member.user_id for member in conversation.members}
    if order.buyer_id not in existing_member_ids:
        conversation.members.append(ConversationMember(user_id=order.buyer_id))
    if seller.user_id not in existing_member_ids:
        conversation.members.append(ConversationMember(user_id=seller.user_id))
    await db.flush()
    return conversation


async def ensure_direct_conversation(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    participant_user_id: uuid.UUID,
) -> Conversation:
    participant_result = await db.execute(
        select(User).where(User.id == participant_user_id)
    )
    participant = participant_result.scalar_one_or_none()
    if participant is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Participant not found.")

    if participant_user_id == user_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail="Cannot start a conversation with yourself.",
        )

    statement = (
        select(Conversation)
        .options(
            selectinload(Conversation.members).selectinload(ConversationMember.user),
            selectinload(Conversation.order),
        )
        .where(
            Conversation.conversation_type == ConversationTypeModel.DIRECT,
            Conversation.members.any(ConversationMember.user_id == user_id),
            Conversation.members.any(ConversationMember.user_id == participant_user_id),
        )
        .limit(1)
    )
    existing_result = await db.execute(statement)
    conversation = existing_result.scalar_one_or_none()
    if conversation is not None:
        await db.flush()
        return conversation

    conversation = Conversation(
        conversation_type=ConversationTypeModel.DIRECT,
        status=ConversationStatusModel.ACTIVE,
    )
    db.add(conversation)
    conversation.members.append(ConversationMember(user_id=user_id))
    conversation.members.append(ConversationMember(user_id=participant_user_id))
    await db.flush()
    return conversation


async def list_conversations_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    status_filter: str | None,
    search: str | None,
) -> ConversationPageResponse:
    return await conversation_page(
        db,
        user_id=user.id,
        cursor=cursor,
        limit=limit,
        status_filter=status_filter,
        search=search,
    )


async def get_conversation_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
) -> ConversationDetailResponse:
    return await conversation_detail_for_user(
        db,
        user_id=user.id,
        conversation_id=conversation_id,
    )


async def list_conversation_messages_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
    cursor: str | None,
    limit: int,
) -> MessagePageResponse:
    await conversation_for_user_or_404(
        db,
        user_id=user.id,
        conversation_id=conversation_id,
    )
    return await conversation_messages(
        db,
        conversation_id=conversation_id,
        cursor=cursor,
        limit=limit,
    )


async def create_conversation_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: ConversationCreateRequest,
) -> ConversationDetailResponse:
    async with db.begin():
        if request.order_id is not None:
            conversation = await ensure_order_conversation(
                db,
                order_id=request.order_id,
                user_id=user.id,
            )
        elif request.participant_user_id is not None:
            conversation = await ensure_direct_conversation(
                db,
                user_id=user.id,
                participant_user_id=request.participant_user_id,
            )
        else:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Either order_id or participant_user_id is required.",
            )

    logger.info(
        "conversation_created",
        conversation_id=str(conversation.id),
        user_id=str(user.id),
        conversation_type=conversation.conversation_type.value,
    )
    return await conversation_detail_for_user(
        db,
        user_id=user.id,
        conversation_id=conversation.id,
    )


async def create_conversation_message_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
    request: MessageCreateRequest,
) -> ConversationDetailResponse:
    async with db.begin():
        conversation = await conversation_for_user_or_404(
            db,
            user_id=user.id,
            conversation_id=conversation_id,
        )
        membership = conversation_member_for_user(conversation, user.id)
        if membership is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Conversation membership not found."
            )

        message = Message(
            conversation_id=conversation.id,
            sender_user_id=user.id,
            body=request.body,
            message_type=MessageTypeModel(request.message_type.value),
        )
        db.add(message)
        await db.flush()
        await db.refresh(message)

        conversation.last_message_id = message.id
        conversation.last_message_at = message.created_at
        conversation.last_message_preview = (message.body or "")[:255]

        for member in conversation.members:
            if member.user_id != user.id:
                member.unread_count_cached = member.unread_count_cached + 1

    await publish_message(
        conversation_id=conversation.id,
        event_type="message.created",
        conversation_data=conversation_summary_response(
            conversation, user.id
        ).model_dump(mode="json"),
        message_data=message_response(message).model_dump(mode="json"),
    )
    logger.info(
        "conversation_message_created",
        conversation_id=str(conversation.id),
        message_id=str(message.id),
        sender_user_id=str(user.id),
    )
    return await conversation_detail_for_user(
        db,
        user_id=user.id,
        conversation_id=conversation.id,
    )


async def mark_conversation_read_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
) -> ConversationMarkReadResponse:
    async with db.begin():
        conversation = await conversation_for_user_or_404(
            db,
            user_id=user.id,
            conversation_id=conversation_id,
        )
        membership = conversation_member_for_user(conversation, user.id)
        if membership is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Conversation membership not found."
            )

        latest_result = await db.execute(
            select(Message)
            .where(Message.conversation_id == conversation.id)
            .order_by(desc(Message.created_at), desc(Message.id))
            .limit(1)
        )
        latest_message = latest_result.scalar_one_or_none()
        membership.last_read_message = latest_message
        membership.unread_count_cached = 0

    await publish_conversation_update(
        conversation_id=conversation.id,
        unread_count=0,
    )
    return ConversationMarkReadResponse(conversation_id=conversation.id, unread_count=0)


async def mark_all_conversations_read_service(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> DetailResponse:
    async with db.begin():
        memberships_result = await db.execute(
            select(ConversationMember)
            .options(
                selectinload(ConversationMember.conversation)
                .selectinload(Conversation.members)
                .selectinload(ConversationMember.user),
                selectinload(ConversationMember.conversation).selectinload(
                    Conversation.order
                ),
            )
            .where(ConversationMember.user_id == user.id)
        )
        memberships = list(memberships_result.scalars().all())
        for membership in memberships:
            latest_result = await db.execute(
                select(Message)
                .where(Message.conversation_id == membership.conversation_id)
                .order_by(desc(Message.created_at), desc(Message.id))
                .limit(1)
            )
            membership.last_read_message = latest_result.scalar_one_or_none()
            membership.unread_count_cached = 0

    for membership in memberships:
        await publish_conversation_update(
            conversation_id=membership.conversation_id,
            unread_count=0,
        )

    return DetailResponse(detail="All conversations marked as read.")


async def mute_conversation_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
    request: MuteConversationRequest,
) -> ConversationDetailResponse:
    async with db.begin():
        conversation = await conversation_for_user_or_404(
            db,
            user_id=user.id,
            conversation_id=conversation_id,
        )
        membership = conversation_member_for_user(conversation, user.id)
        if membership is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Conversation membership not found."
            )
        membership.muted_until = request.muted_until

    member = conversation_member_for_user(conversation, user.id)
    await publish_conversation_update(
        conversation_id=conversation.id,
        unread_count=member.unread_count_cached if member else 0,
    )
    return await conversation_detail_for_user(
        db,
        user_id=user.id,
        conversation_id=conversation.id,
    )


async def resolve_conversation_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
) -> ConversationDetailResponse:
    async with db.begin():
        conversation = await conversation_for_user_or_404(
            db,
            user_id=user.id,
            conversation_id=conversation_id,
        )
        conversation.status = ConversationStatusModel.RESOLVED
        conversation.resolved_at = datetime.now(timezone.utc)

    await publish_conversation_update(
        conversation_id=conversation.id,
        unread_count=0,
    )
    return await conversation_detail_for_user(
        db,
        user_id=user.id,
        conversation_id=conversation.id,
    )


async def clear_conversation_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    conversation_id: uuid.UUID,
) -> DetailResponse:
    async with db.begin():
        conversation = await conversation_for_user_or_404(
            db,
            user_id=user.id,
            conversation_id=conversation_id,
        )
        membership = conversation_member_for_user(conversation, user.id)
        if membership is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Conversation membership not found."
            )
        membership.cleared_at = datetime.now(timezone.utc)

    member = conversation_member_for_user(conversation, user.id)
    await publish_conversation_update(
        conversation_id=conversation.id,
        unread_count=member.unread_count_cached if member else 0,
    )
    return DetailResponse(detail="Conversation cleared.")


async def clear_resolved_conversations_service(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> DetailResponse:
    async with db.begin():
        memberships_result = await db.execute(
            select(ConversationMember)
            .options(
                selectinload(ConversationMember.conversation)
                .selectinload(Conversation.members)
                .selectinload(ConversationMember.user),
                selectinload(ConversationMember.conversation).selectinload(
                    Conversation.order
                ),
            )
            .where(
                ConversationMember.user_id == user.id,
                ConversationMember.conversation.has(
                    Conversation.status == ConversationStatusModel.RESOLVED
                ),
            )
        )
        memberships = list(memberships_result.scalars().all())
        now = datetime.now(timezone.utc)
        for membership in memberships:
            membership.cleared_at = now

    for membership in memberships:
        await publish_conversation_update(
            conversation_id=membership.conversation_id,
            unread_count=0,
        )

    return DetailResponse(detail="Resolved conversations cleared.")
