import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Literal, Protocol

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.exceptions import GoogleAuthError
from src.api.v1.auth.queries import (
    get_email_verification_otp,
    get_password_reset_otp,
    get_user_by_id,
)
from src.api.v1.auth.schema import (
    AddressRequest,
    AddressResponse,
    CoordinatesResponse,
    LocationResponse,
)
from src.api.v1.locations.utils import (
    resolve_address_input,  # noqa: F401 - re-exported in service.py
)
from src.core.config import settings
from src.core.database import get_db
from src.models import UserAccountStatus, UserRole
from src.models.auth import Address, EmailVerificationOTP, RefreshTokenBlacklist, User
from src.utils.email import send_email


class OTPRecord(Protocol):
    is_used: bool
    code: str
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class JWTPayload:
    user_id: uuid.UUID
    email: str
    role: UserRole
    account_status: UserAccountStatus


class AuthenticatedActor(Protocol):
    id: uuid.UUID
    email: str
    role: UserRole
    account_status: UserAccountStatus


@dataclass(frozen=True, slots=True)
class AuthenticatedUser:
    id: uuid.UUID
    email: str
    role: UserRole
    account_status: UserAccountStatus


type TokenType = Literal["access", "refresh"]


def encode_token(user: User, token_type: TokenType) -> str:
    issued_at = datetime.now(timezone.utc)
    expires_at = token_expiry(token_type)
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "role": user.role.value,
        "account_status": user.account_status.value,
        "type": token_type,
        "jti": uuid.uuid4().hex,
        "iat": int(issued_at.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    return jwt.encode(
        payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )


def create_token_pair(user: User) -> tuple[str, str]:
    access_token = encode_token(user, "access")
    refresh_token = encode_token(user, "refresh")
    return access_token, refresh_token


def decode_token(token: str, expected_type: TokenType = "access") -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )

        if payload.get("type") != expected_type:
            raise HTTPException(
                status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
                headers={"WWW-Authenticate": "Bearer"},
            )

    except ExpiredSignatureError as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except JWTError as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    return payload


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
) -> JWTPayload:
    payload = decode_token(credentials.credentials)

    user_id_str = payload.get("sub")
    email = payload.get("email")
    role_str = payload.get("role")
    account_status_str = payload.get("account_status")

    if not user_id_str or not email or not role_str or not account_status_str:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        jwt_payload = JWTPayload(
            user_id=uuid.UUID(user_id_str),
            email=str(email),
            role=UserRole(role_str),
            account_status=UserAccountStatus(account_status_str),
        )
    except (ValueError, KeyError) as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    return jwt_payload


def get_authenticated_user(user=Depends(get_current_user)) -> JWTPayload:
    if user.account_status != UserAccountStatus.ACTIVE:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, detail="User account is not active"
        )
    return user


def get_current_authenticated_actor(
    jwt_payload: JWTPayload = Depends(get_authenticated_user),
) -> AuthenticatedUser:
    return AuthenticatedUser(
        id=jwt_payload.user_id,
        email=jwt_payload.email,
        role=jwt_payload.role,
        account_status=jwt_payload.account_status,
    )


async def get_current_authenticated_user(
    db: AsyncSession = Depends(get_db),
    jwt_payload: JWTPayload = Depends(get_authenticated_user),
) -> User:
    user = await get_user_by_id(db, jwt_payload.user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


def require_roles(*allowed_roles: UserRole):
    async def role_checker(user=Depends(get_authenticated_user)) -> JWTPayload:
        if not allowed_roles:
            raise ValueError("At least one role must be specified for role checking")
        if user.role not in allowed_roles:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN, detail="Insufficient permissions"
            )
        return user

    return role_checker


@dataclass(frozen=True, slots=True)
class GoogleIdentity:
    """Verified identity from a Google ID token."""

    provider_user_id: str
    email: str
    email_verified: bool
    full_name: str


def verify_google_id_token(raw_id_token: str) -> GoogleIdentity:
    if not settings.GOOGLE_CLIENT_IDS:
        raise GoogleAuthError("Google client IDs not configured")

    request = google_requests.Request()

    payload = None
    for audience in settings.GOOGLE_CLIENT_IDS:
        try:
            payload = id_token.verify_oauth2_token(raw_id_token, request, audience)
            break
        except Exception:  # nosec: B112
            continue

    if payload is None:
        raise GoogleAuthError("Token verification failed for all configured client IDs")

    email = payload.get("email")
    sub = payload.get("sub")

    if not email or not sub:
        raise GoogleAuthError("Token missing required claims (email, sub)")

    return GoogleIdentity(
        provider_user_id=sub,
        email=email,
        email_verified=bool(payload.get("email_verified", False)),
        full_name=payload.get("name") or "",
    )


async def get_user_from_access_token(db: AsyncSession, token: str) -> User:
    payload = decode_token(token, expected_type="access")
    jti = payload.get("jti")
    sub = payload.get("sub")
    if not jti or not sub:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    if await is_blacklisted(db, jti):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Token revoked")

    try:
        user_id = uuid.UUID(str(sub))
    except ValueError as exc:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        ) from exc

    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


def ensure_user_can_authenticate(
    user: User, *, allow_unverified_email: bool = False
) -> None:
    now = datetime.now(timezone.utc)
    if (
        user.account_status == UserAccountStatus.SUSPENDED
        and user.suspended_until
        and user.suspended_until <= now
    ):
        user.account_status = UserAccountStatus.ACTIVE
        user.suspended_until = None
    if user.account_status == UserAccountStatus.BANNED:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, detail="This account is not allowed to login."
        )
    if (
        user.account_status == UserAccountStatus.SUSPENDED
        and user.suspended_until
        and user.suspended_until > now
    ):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, detail="This account is not allowed to login."
        )
    if not allow_unverified_email and not user.is_email_verified:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail="Email not verified. Please verify your email first.",
        )


def address_response(address: Address) -> AddressResponse:
    return AddressResponse(
        id=address.id,
        location=LocationResponse(
            id=address.id,
            name=address.name,
            address_text=address.address_text,
            coordinates=CoordinatesResponse(
                latitude=address.latitude,
                longitude=address.longitude,
            ),
        ),
        is_default=address.is_default,
        created_at=address.created_at,
    )


def apply_address_request(
    address: Address,
    request: AddressRequest,
    *,
    latitude: float,
    longitude: float,
) -> None:
    """Copy address request fields onto an Address model."""

    address.name = request.name
    address.address_text = request.address_text or ""
    address.latitude = latitude
    address.longitude = longitude
    address.is_default = request.is_default


async def upsert_email_verification_otp(db: AsyncSession, user: User) -> None:
    code = generate_otp_code()
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.EMAIL_VERIFICATION_OTP_EXPIRE_MINUTES
    )
    otp = await get_email_verification_otp(db, user)
    if otp:
        otp.code = code
        otp.is_used = False
        otp.expires_at = expires_at
    else:
        db.add(EmailVerificationOTP(user_id=user.id, code=code, expires_at=expires_at))
    await send_email(
        user.email,
        "Your Hustlers email verification code",
        html=f"<p>Your verification code is <strong>{code}</strong>.</p>",
    )


async def upsert_password_reset_otp(db: AsyncSession, user: User) -> str:
    """Create or update password reset OTP and return the code."""
    from src.models.auth import PasswordResetOTP

    code = generate_otp_code()
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.PASSWORD_RESET_OTP_EXPIRE_MINUTES
    )
    existing_otp = await get_password_reset_otp(db, user)
    if existing_otp:
        existing_otp.code = code
        existing_otp.is_verified = False
        existing_otp.verified_token = None
        existing_otp.is_used = False
        existing_otp.expires_at = expires_at
    else:
        db.add(PasswordResetOTP(user_id=user.id, code=code, expires_at=expires_at))
    await send_email(
        user.email,
        "Your Hustlers password reset code",
        html=f"<p>Your verification code is <strong>{code}</strong>.</p>",
    )
    return code


def otp_is_active(otp: OTPRecord | None, code: str) -> bool:
    """Validate OTP is active and hasn't expired."""

    return bool(
        otp
        and not otp.is_used
        and otp.code == code
        and otp.expires_at > datetime.now(timezone.utc)
    )


def token_expiry(token_type: TokenType) -> datetime:
    """Calculate token expiration time based on token type."""
    if token_type == "access":  # nosec: B105
        return datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    return datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )


def generate_otp_code() -> str:
    """Generate a random 6-digit OTP code."""
    code = secrets.randbelow(1_000_000)
    return f"{code:06d}"


async def is_blacklisted(db: AsyncSession, jti: str) -> bool:
    """Check if a token JTI is blacklisted."""
    from sqlalchemy import select

    stmt = select(RefreshTokenBlacklist.id).where(RefreshTokenBlacklist.jti == jti)
    result = await db.execute(stmt)
    return result.scalar_one_or_none() is not None


async def create_blacklist_entry(
    db: AsyncSession,
    user_id: uuid.UUID,
    jti: str,
    token_type: str,
    expires_at: datetime,
    *,
    reason: str | None = None,
) -> None:
    """Create a token blacklist entry in the database."""
    if await is_blacklisted(db, jti):
        return
    db.add(
        RefreshTokenBlacklist(
            user_id=user_id,
            jti=jti,
            token_type=token_type,
            reason=reason,
            expires_at=expires_at,
        )
    )


async def blacklist_token(
    db: AsyncSession,
    token: str,
    *,
    expected_type: Literal["access", "refresh"] | None = None,
    reason: str | None = None,
) -> None:
    """Blacklist a token by decoding it and adding to blacklist table."""
    payload = decode_token(token, expected_type=expected_type or "access")
    jti = payload.get("jti")
    sub = payload.get("sub")
    exp = payload.get("exp")
    if not jti or not sub or not exp:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    await create_blacklist_entry(
        db,
        user_id=uuid.UUID(str(sub)),
        jti=jti,
        token_type=str(payload.get("type", expected_type or "token")),
        expires_at=datetime.fromtimestamp(int(exp), tz=timezone.utc),
        reason=reason,
    )
