import uuid

from fastapi import status
from sqlalchemy import and_, delete, desc, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.exceptions import HTTPException
from src.models.auth import User
from src.models.messaging import Conversation, ConversationMember
from src.models.orders import Order
from src.models.sellers import SellerPresence, SellerProfile
from src.models.trust import UserBlock, UserReport, UserVerification


async def get_user_verification(
    db: AsyncSession, user_id: uuid.UUID
) -> UserVerification | None:
    """Fetch the most recent verification for a user."""
    result = await db.execute(
        select(UserVerification)
        .where(UserVerification.user_id == user_id)
        .order_by(desc(UserVerification.created_at), desc(UserVerification.id))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_verification_by_provider_reference(
    db: AsyncSession,
    provider_reference: str,
    provider_name: str | None = None,
) -> UserVerification | None:
    """Fetch verification by provider reference."""
    filters = [UserVerification.provider_reference == provider_reference]
    if provider_name:
        filters.append(UserVerification.provider_name == provider_name)

    result = await db.execute(
        select(UserVerification)
        .options(selectinload(UserVerification.user))
        .where(and_(*filters))
        .order_by(desc(UserVerification.created_at), desc(UserVerification.id))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    """Fetch user by ID."""
    result = await db.execute(select(User).where(User.id == user_id).limit(1))
    return result.scalar_one_or_none()


async def get_block_by_id(db: AsyncSession, block_id: uuid.UUID) -> UserBlock | None:
    """Fetch a block by ID with blocked user loaded."""
    result = await db.execute(
        select(UserBlock)
        .options(selectinload(UserBlock.blocked_user))
        .where(UserBlock.id == block_id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_block(
    db: AsyncSession,
    blocker_user_id: uuid.UUID,
    blocked_user_id: uuid.UUID,
) -> UserBlock | None:
    """Fetch a block between two users."""
    result = await db.execute(
        select(UserBlock)
        .options(selectinload(UserBlock.blocked_user))
        .where(
            UserBlock.blocker_user_id == blocker_user_id,
            UserBlock.blocked_user_id == blocked_user_id,
        )
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_blocks_by_user(
    db: AsyncSession,
    user_id: uuid.UUID,
    cursor: str | None,
    limit: int,
):
    """Fetch blocks for a user with cursor pagination."""
    from src.api.v1.trust.utils import parse_timestamp_cursor

    safe_limit = min(max(limit, 1), 100)
    statement = (
        select(UserBlock)
        .options(selectinload(UserBlock.blocked_user))
        .where(UserBlock.blocker_user_id == user_id)
        .order_by(desc(UserBlock.created_at), desc(UserBlock.id))
    )

    if cursor is not None:
        cursor_created_at, cursor_id = parse_timestamp_cursor(cursor)
        statement = statement.where(
            or_(
                UserBlock.created_at < cursor_created_at,
                and_(
                    UserBlock.created_at == cursor_created_at,
                    UserBlock.id < cursor_id,
                ),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    blocks = result.scalars().all()
    has_more = len(blocks) > safe_limit
    return blocks[:safe_limit], has_more


async def delete_block(
    db: AsyncSession,
    blocker_user_id: uuid.UUID,
    blocked_user_id: uuid.UUID,
) -> None:
    """Delete a block between two users."""
    await db.execute(
        delete(UserBlock).where(
            UserBlock.blocker_user_id == blocker_user_id,
            UserBlock.blocked_user_id == blocked_user_id,
        )
    )


async def get_report_by_id(db: AsyncSession, report_id: uuid.UUID) -> UserReport | None:
    """Fetch a report by ID with reported user loaded."""
    result = await db.execute(
        select(UserReport)
        .options(selectinload(UserReport.reported_user))
        .where(UserReport.id == report_id)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_reports_by_user(
    db: AsyncSession,
    user_id: uuid.UUID,
    cursor: str | None,
    limit: int,
):
    """Fetch reports reported by a user with cursor pagination."""
    from src.api.v1.trust.utils import parse_timestamp_cursor

    safe_limit = min(max(limit, 1), 100)
    statement = (
        select(UserReport)
        .options(selectinload(UserReport.reported_user))
        .where(UserReport.reporter_user_id == user_id)
        .order_by(desc(UserReport.created_at), desc(UserReport.id))
    )

    if cursor is not None:
        cursor_created_at, cursor_id = parse_timestamp_cursor(cursor)
        statement = statement.where(
            or_(
                UserReport.created_at < cursor_created_at,
                and_(
                    UserReport.created_at == cursor_created_at,
                    UserReport.id < cursor_id,
                ),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    reports = result.scalars().all()
    has_more = len(reports) > safe_limit
    return reports[:safe_limit], has_more


async def get_admin_reports(
    db: AsyncSession,
    status_filter: str | None,
    cursor: str | None,
    limit: int,
):
    """Fetch all reports for admin with optional status filter and cursor pagination."""
    from src.api.v1.trust.utils import parse_timestamp_cursor
    from src.models.trust import UserReportStatus

    safe_limit = min(max(limit, 1), 100)
    statement = (
        select(UserReport)
        .options(selectinload(UserReport.reported_user))
        .order_by(desc(UserReport.created_at), desc(UserReport.id))
    )

    normalized_status = (status_filter or "").strip().lower()
    if normalized_status:
        valid_statuses = {item.value for item in UserReportStatus}
        if normalized_status not in valid_statuses:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail={
                    "status": [
                        "Invalid status. Expected one of: pending, reviewed, resolved, dismissed."
                    ]
                },
            )
        statement = statement.where(UserReport.status == normalized_status)

    if cursor is not None:
        cursor_created_at, cursor_id = parse_timestamp_cursor(cursor)
        statement = statement.where(
            or_(
                UserReport.created_at < cursor_created_at,
                and_(
                    UserReport.created_at == cursor_created_at,
                    UserReport.id < cursor_id,
                ),
            )
        )

    result = await db.execute(statement.limit(safe_limit + 1))
    reports = result.scalars().all()
    has_more = len(reports) > safe_limit
    return reports[:safe_limit], has_more


async def get_report_for_update(
    db: AsyncSession, report_id: uuid.UUID
) -> UserReport | None:
    """Fetch a report with row lock for update."""
    result = await db.execute(
        select(UserReport)
        .options(selectinload(UserReport.reported_user))
        .where(UserReport.id == report_id)
        .with_for_update()
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_order_by_id(db: AsyncSession, order_id: uuid.UUID) -> Order | None:
    """Fetch an order by ID."""
    result = await db.execute(select(Order).where(Order.id == order_id).limit(1))
    return result.scalar_one_or_none()


async def get_conversation_by_id(
    db: AsyncSession, conversation_id: uuid.UUID
) -> Conversation | None:
    """Fetch a conversation by ID."""
    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation_id).limit(1)
    )
    return result.scalar_one_or_none()


async def is_conversation_member(
    db: AsyncSession, conversation_id: uuid.UUID, user_id: uuid.UUID
) -> bool:
    """Check if user is a member of a conversation."""
    result = await db.execute(
        select(ConversationMember.id)
        .where(
            ConversationMember.conversation_id == conversation_id,
            ConversationMember.user_id == user_id,
        )
        .limit(1)
    )
    return result.scalar_one_or_none() is not None


async def get_user_seller_profile(
    db: AsyncSession, user_id: uuid.UUID
) -> SellerProfile | None:
    """Fetch seller profile for a user."""
    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user_id).limit(1)
    )
    return result.scalar_one_or_none()


async def get_seller_presence(
    db: AsyncSession, seller_id: uuid.UUID
) -> SellerPresence | None:
    """Fetch seller presence."""
    result = await db.execute(
        select(SellerPresence).where(SellerPresence.seller_id == seller_id).limit(1)
    )
    return result.scalar_one_or_none()
