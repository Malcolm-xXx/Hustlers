from uuid import UUID

from fastapi import APIRouter, Query

from src.api.v1.messaging.schema import (
    ConversationCreateRequest,
    ConversationDetailResponse,
    ConversationMarkReadResponse,
    ConversationPageResponse,
    DetailResponse,
    MessageCreateRequest,
    MessagePageResponse,
    MuteConversationRequest,
)
from src.api.v1.messaging.service import (
    clear_conversation_service,
    clear_resolved_conversations_service,
    create_conversation_message_service,
    create_conversation_service,
    get_conversation_service,
    list_conversation_messages_service,
    list_conversations_service,
    mark_all_conversations_read_service,
    mark_conversation_read_service,
    mute_conversation_service,
    resolve_conversation_service,
)
from src.utils.dependencies import AuthenticatedActorContext

router = APIRouter()


@router.get("/conversations/", response_model=ConversationPageResponse)
async def list_conversations(
    *,
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    status: str | None = Query(default=None),
    search: str | None = Query(default=None),
):
    return await list_conversations_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        status,
        search,
    )


@router.get(
    "/conversations/{conversation_id}/", response_model=ConversationDetailResponse
)
async def get_conversation(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await get_conversation_service(
        auth_context.db, auth_context.user, conversation_id
    )


@router.get(
    "/conversations/{conversation_id}/messages/", response_model=MessagePageResponse
)
async def list_conversation_messages(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_conversation_messages_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
        cursor,
        limit,
    )


@router.post(
    "/conversations/",
    response_model=ConversationDetailResponse,
    status_code=201,
)
async def create_conversation(
    request: ConversationCreateRequest,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await create_conversation_service(
        auth_context.db, auth_context.user, request
    )


@router.post(
    "/conversations/{conversation_id}/messages/",
    response_model=ConversationDetailResponse,
    status_code=201,
)
async def create_conversation_message(
    conversation_id: UUID,
    request: MessageCreateRequest,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await create_conversation_message_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
        request,
    )


@router.post(
    "/conversations/{conversation_id}/mark-read/",
    response_model=ConversationMarkReadResponse,
)
async def mark_conversation_read(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await mark_conversation_read_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
    )


@router.post("/conversations/mark-all-read/", response_model=DetailResponse)
async def mark_all_conversations_read(
    *,
    auth_context: AuthenticatedActorContext,
):
    return await mark_all_conversations_read_service(auth_context.db, auth_context.user)


@router.post(
    "/conversations/{conversation_id}/mute/", response_model=ConversationDetailResponse
)
async def mute_conversation(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
    request: MuteConversationRequest,
):
    return await mute_conversation_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
        request,
    )


@router.post(
    "/conversations/{conversation_id}/resolve/",
    response_model=ConversationDetailResponse,
)
async def resolve_conversation(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await resolve_conversation_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
    )


@router.delete("/conversations/{conversation_id}/clear/", response_model=DetailResponse)
async def clear_conversation(
    conversation_id: UUID,
    *,
    auth_context: AuthenticatedActorContext,
):
    return await clear_conversation_service(
        auth_context.db,
        auth_context.user,
        conversation_id,
    )


@router.delete("/conversations/clear-resolved/", response_model=DetailResponse)
async def clear_resolved_conversations(
    *,
    auth_context: AuthenticatedActorContext,
):
    return await clear_resolved_conversations_service(
        auth_context.db, auth_context.user
    )
