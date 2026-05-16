from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    JSON,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

if TYPE_CHECKING:
    from src.models.auth import User
    from src.models.messaging import Conversation


class UserVerificationStatus(enum.Enum):
    NOT_STARTED = "not_started"
    PENDING = "pending"
    VERIFIED = "verified"
    FAILED = "failed"


class UserVerificationIDDocumentType(enum.Enum):
    ID_CARD = "id_card"
    NIN = "nin"
    DRIVERS_LICENSE = "drivers_license"
    PASSPORT = "passport"


class UserReportStatus(enum.Enum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class UserVerification(Base):
    __tablename__ = "user_verifications"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    status: Mapped[UserVerificationStatus] = mapped_column(
        Enum(UserVerificationStatus, native_enum=False),
        default=UserVerificationStatus.NOT_STARTED,
        nullable=False,
    )
    id_document_type: Mapped[UserVerificationIDDocumentType] = mapped_column(
        Enum(UserVerificationIDDocumentType, native_enum=False),
        default=UserVerificationIDDocumentType.ID_CARD,
        nullable=False,
    )
    id_document_image_url: Mapped[str | None] = mapped_column(
        String(500), nullable=True
    )
    id_document_image_cloudinary_public_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    face_capture_image_url: Mapped[str | None] = mapped_column(
        String(500), nullable=True
    )
    face_capture_image_cloudinary_public_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    provider_name: Mapped[str] = mapped_column(String(100), default="")
    provider_reference: Mapped[str] = mapped_column(String(255), default="")
    provider_payload_json: Mapped[dict[str, object]] = mapped_column(JSON, default=dict)
    failure_reason: Mapped[str] = mapped_column(Text, default="")
    submitted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["User"] = relationship("User", foreign_keys=[user_id])


class UserBlock(Base):
    __tablename__ = "user_blocks"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    blocker_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    blocked_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    blocker_user: Mapped["User"] = relationship("User", foreign_keys=[blocker_user_id])
    blocked_user: Mapped["User"] = relationship("User", foreign_keys=[blocked_user_id])

    __table_args__ = (
        UniqueConstraint(
            "blocker_user_id",
            "blocked_user_id",
            name="uq_user_blocks_blocker_blocked",
        ),
        Index("idx_user_blocks_blocker", "blocker_user_id"),
    )


class UserReport(Base):
    __tablename__ = "user_reports"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    reporter_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    reported_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    order_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("orders.id"), nullable=True
    )
    conversation_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("conversations.id", ondelete="SET NULL"), nullable=True
    )
    reason_type: Mapped[str] = mapped_column(String(100), nullable=False)
    details: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[UserReportStatus] = mapped_column(
        Enum(UserReportStatus, native_enum=False),
        default=UserReportStatus.PENDING,
        nullable=False,
    )
    resolution_note: Mapped[str] = mapped_column(Text, default="")
    resolved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    reporter_user: Mapped["User"] = relationship(
        "User", foreign_keys=[reporter_user_id]
    )
    reported_user: Mapped["User"] = relationship(
        "User", foreign_keys=[reported_user_id]
    )
    resolved_by_user: Mapped["User | None"] = relationship(
        "User", foreign_keys=[resolved_by_user_id]
    )
    conversation: Mapped["Conversation | None"] = relationship(
        "Conversation", foreign_keys=[conversation_id]
    )

    __table_args__ = (
        Index("idx_urep_reporter_created", "reporter_user_id", "created_at"),
        Index("idx_urep_status_created", "status", "created_at"),
        Index("idx_urep_conversation", "conversation_id"),
    )
