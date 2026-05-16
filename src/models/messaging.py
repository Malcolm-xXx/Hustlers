from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.orders import Order
    from src.models.auth import User


class ConversationType(enum.Enum):
    DIRECT = "direct"
    ORDER = "order"


class ConversationStatus(enum.Enum):
    ACTIVE = "active"
    RESOLVED = "resolved"


class Conversation(Base):
    __tablename__ = "conversations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    conversation_type: Mapped[ConversationType] = mapped_column(
        Enum(ConversationType, native_enum=False),
        default=ConversationType.DIRECT,
    )
    order_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("orders.id"), nullable=True
    )
    status: Mapped[ConversationStatus] = mapped_column(
        Enum(ConversationStatus, native_enum=False),
        default=ConversationStatus.ACTIVE,
    )
    last_message_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True, index=True)
    last_message_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_message_preview: Mapped[str] = mapped_column(String(255), default="")

    last_message: Mapped["Message | None"] = relationship(
        "Message",
        foreign_keys="[Conversation.last_message_id]",
        post_update=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    order: Mapped["Order | None"] = relationship(
        "Order",
        uselist=False,
        foreign_keys=[order_id],
    )
    members: Mapped[list["ConversationMember"]] = relationship(
        "ConversationMember",
        back_populates="conversation",
        cascade="all, delete-orphan",
    )
    messages: Mapped[list["Message"]] = relationship(
        "Message",
        back_populates="conversation",
        cascade="all, delete-orphan",
    )

    __table_args__ = (Index("idx_conv_status_lastmsg", "status", "last_message_at"),)


class ConversationMember(Base):
    __tablename__ = "conversation_members"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    last_read_message_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("messages.id", ondelete="SET NULL"), nullable=True
    )
    unread_count_cached: Mapped[int] = mapped_column(Integer, default=0)
    muted_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    cleared_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    conversation: Mapped["Conversation"] = relationship(
        "Conversation", back_populates="members"
    )
    user: Mapped["User"] = relationship(
        "User", back_populates="conversation_memberships"
    )
    last_read_message: Mapped["Message | None"] = relationship(
        "Message", foreign_keys=[last_read_message_id]
    )

    __table_args__ = (
        UniqueConstraint(
            "conversation_id", "user_id", name="uq_conversation_members_conv_user"
        ),
        Index("idx_conv_members_user_joined", "user_id", "joined_at"),
        Index("idx_conv_members_conversation", "conversation_id"),
    )


class MessageType(enum.Enum):
    TEXT = "text"
    SYSTEM = "system"


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id"), nullable=False
    )
    sender_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    message_type: Mapped[MessageType] = mapped_column(
        Enum(MessageType, native_enum=False),
        default=MessageType.TEXT,
    )
    body: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    edited_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    conversation: Mapped["Conversation"] = relationship(
        "Conversation", back_populates="messages"
    )
    sender_user: Mapped["User | None"] = relationship("User")
    attachments: Mapped[list["MessageAttachment"]] = relationship(
        "MessageAttachment",
        back_populates="message",
        cascade="all, delete-orphan",
    )

    __table_args__ = (Index("idx_msg_conv_created", "conversation_id", "created_at"),)


class MessageAttachment(Base):
    ALLOWED_CONTENT_TYPES = frozenset(
        ["image/jpeg", "image/png", "image/gif", "application/pdf"]
    )
    MAX_FILE_SIZE = 10 * 1024 * 1024

    __tablename__ = "message_attachments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("messages.id"), nullable=False
    )
    file_url: Mapped[str] = mapped_column(String(500), nullable=False)
    cloudinary_public_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    original_filename: Mapped[str] = mapped_column(String(255), default="")
    file_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    content_type: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    message: Mapped["Message"] = relationship("Message", back_populates="attachments")
