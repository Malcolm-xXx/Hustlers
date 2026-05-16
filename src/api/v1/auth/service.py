import secrets
import uuid
from datetime import datetime, timezone

from fastapi import status
from passlib.context import CryptContext
from pydantic import HttpUrl
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.exceptions import GoogleAuthError
from src.api.v1.auth.queries import (
    get_address_or_404,
    get_addresses_by_user,
    get_email_verification_otp,
    get_password_reset_otp,
    get_user_by_email,
    get_user_by_id,
    unset_default_addresses,
)
from src.api.v1.auth.schema import (
    AddressRequest,
    AddressResponse,
    GoogleLoginRequest,
    GoogleLoginResponse,
    LoginRequest,
    LoginResponse,
    LogoutRequest,
    PasswordResetConfirmRequest,
    PasswordResetRequest,
    PasswordResetVerifyOtpRequest,
    PasswordResetVerifyOtpResponse,
    RegisterRequest,
    RegisterResponse,
    ResendEmailOtpRequest,
    TokenRefreshRequest,
    TokenRefreshResponse,
    UserMeResponse,
    UserMeUpdateRequest,
    VerifyEmailOtpRequest,
)
from src.api.v1.auth.utils import (
    address_response,
    apply_address_request,
    blacklist_token,
    create_token_pair,
    decode_token,
    ensure_user_can_authenticate,
    is_blacklisted,
    otp_is_active,
    resolve_address_input,
    upsert_email_verification_otp,
    upsert_password_reset_otp,
    verify_google_id_token,
)
from src.api.v1.shared.serializers import build_user_summary
from src.core.logging import get_logger
from src.core.exceptions import HTTPException
from src.models.auth import (
    Address,
    User,
)
from src.utils.images import get_image_provider

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
logger = get_logger(__name__)


async def register_service(
    db: AsyncSession, request: RegisterRequest
) -> RegisterResponse:
    email = request.email.lower()
    existing = await get_user_by_email(db, email)
    if existing:
        raise HTTPException(
            status.HTTP_409_CONFLICT, detail="Email already registered."
        )

    user = User(
        full_name=request.full_name,
        phone_number=request.phone_number,
        email=email,
        password_hash=pwd_context.hash(request.password),
        is_email_verified=False,
    )
    db.add(user)
    await db.flush()
    await upsert_email_verification_otp(db, user)
    logger.info("user_registered", user_id=str(user.id))

    return RegisterResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number or "",
        role=user.role,
        is_onboarded=user.is_onboarded,
        detail="Verification OTP sent to email.",
        requires_email_verification=True,
    )


async def verify_email_otp_service(
    db: AsyncSession, request: VerifyEmailOtpRequest
) -> dict[str, str]:
    user = await get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid or expired verification code."
        )

    otp = await get_email_verification_otp(db, user)
    if not otp or not otp_is_active(otp, request.otp):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid or expired verification code."
        )

    otp.is_used = True
    user.is_email_verified = True
    return {"detail": "Email verified successfully."}


async def resend_email_otp_service(
    db: AsyncSession, request: ResendEmailOtpRequest
) -> dict[str, str]:
    user = await get_user_by_email(db, request.email)
    if user and not user.is_email_verified:
        await upsert_email_verification_otp(db, user)
    return {"detail": "Verification OTP sent if account exists."}


async def login_service(db: AsyncSession, request: LoginRequest) -> LoginResponse:
    user = await get_user_by_email(db, request.email)
    if (
        not user
        or not user.password_hash
        or not pwd_context.verify(request.password, user.password_hash)
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")

    ensure_user_can_authenticate(user)
    access, refresh = create_token_pair(user)
    logger.info("user_logged_in", user_id=str(user.id))
    return LoginResponse(access=access, refresh=refresh, user=build_user_summary(user))


async def refresh_tokens_service(
    db: AsyncSession, request: TokenRefreshRequest
) -> TokenRefreshResponse:
    payload = decode_token(request.refresh, expected_type="refresh")
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

    ensure_user_can_authenticate(user)
    access, refresh = create_token_pair(user)
    await blacklist_token(
        db, request.refresh, expected_type="refresh", reason="rotated"
    )
    return TokenRefreshResponse(access=access, refresh=refresh)


async def logout_service(db: AsyncSession, request: LogoutRequest) -> dict[str, str]:
    await blacklist_token(db, request.access, expected_type="access", reason="logout")
    await blacklist_token(db, request.refresh, expected_type="refresh", reason="logout")
    return {"detail": "Logged out successfully."}


async def google_login_service(
    db: AsyncSession, request: GoogleLoginRequest
) -> GoogleLoginResponse:
    try:
        identity = verify_google_id_token(request.id_token)
    except GoogleAuthError as exc:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Google authentication failed."
        ) from exc

    if not identity.email_verified:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Google authentication failed."
        )

    email = identity.email.lower()
    user = await get_user_by_email(db, email)
    is_new_user = False

    if user:
        ensure_user_can_authenticate(user, allow_unverified_email=True)
        user.google_uid = user.google_uid or identity.provider_user_id
        user.is_email_verified = True
        if identity.full_name and not user.full_name:
            user.full_name = identity.full_name
    else:
        user = User(
            full_name=identity.full_name or email.split("@")[0],
            email=email,
            google_uid=identity.provider_user_id,
            is_email_verified=True,
            password_hash=None,
        )
        db.add(user)
        await db.flush()
        is_new_user = True

    access, refresh = create_token_pair(user)
    logger.info(
        "google_login_succeeded",
        user_id=str(user.id),
        is_new_user=is_new_user,
    )
    return GoogleLoginResponse(
        access=access,
        refresh=refresh,
        user=build_user_summary(user),
        is_new_user=is_new_user,
    )


async def request_password_reset_service(
    db: AsyncSession, request: PasswordResetRequest
) -> dict[str, str]:
    user = await get_user_by_email(db, request.email)
    if user:
        await upsert_password_reset_otp(db, user)
    return {"detail": "Password reset OTP sent if account exists."}


async def verify_password_reset_otp_service(
    db: AsyncSession, request: PasswordResetVerifyOtpRequest
) -> PasswordResetVerifyOtpResponse:
    user = await get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset code."
        )

    otp = await get_password_reset_otp(db, user)
    if not otp or not otp_is_active(otp, request.otp):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset code."
        )

    verification_token = secrets.token_urlsafe(24)
    otp.is_verified = True
    otp.verified_token = verification_token
    return PasswordResetVerifyOtpResponse(
        detail="Reset code verified successfully.",
        verification_token=verification_token,
    )


async def confirm_password_reset_service(
    db: AsyncSession, request: PasswordResetConfirmRequest
) -> dict[str, str]:
    user = await get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid reset verification token."
        )

    otp = await get_password_reset_otp(db, user)
    if not (
        otp
        and otp.is_verified
        and not otp.is_used
        and otp.verified_token == request.verification_token
        and otp.expires_at > datetime.now(timezone.utc)
    ):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, detail="Invalid reset verification token."
        )

    user.password_hash = pwd_context.hash(request.new_password)
    otp.is_used = True
    otp.verified_token = None
    return {"detail": "Password reset successful."}


async def get_me_service(db: AsyncSession, user: User) -> UserMeResponse:
    addresses = await list_addresses_service(db, user)
    default_address = next(
        (address for address in addresses if address.is_default), None
    )
    return UserMeResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone_number=user.phone_number,
        profile_photo_url=HttpUrl(user.profile_photo_url)
        if user.profile_photo_url
        else None,
        role=user.role,
        is_onboarded=user.is_onboarded,
        onboarding_data=user.onboarding_data or {},
        default_delivery_address=default_address,
        saved_addresses=addresses,
        created_at=user.created_at,
    )


async def generate_profile_photo_upload_url_service(
    db: AsyncSession, user: User
) -> dict:
    """Generate a presigned upload URL for a profile photo."""
    provider = get_image_provider()
    presigned_response = await provider.generate_presigned_url(
        folder=f"profiles/users/{user.id}",
        file_type="profile_photo",
        resource_type="image",
        expiration_minutes=15,
    )

    return {
        "upload_url": presigned_response.upload_url,
        "public_id": presigned_response.public_id,
        "signature": presigned_response.signature,
        "api_key": presigned_response.api_key,
        "timestamp": presigned_response.timestamp,
        "expires_in": presigned_response.expires_in,
        "allowed_types": presigned_response.allowed_types,
    }


async def update_profile_photo_from_url_service(
    db: AsyncSession, user: User, photo_url: str, public_id: str
) -> UserMeResponse:
    """Update profile photo after presigned upload to Cloudinary."""
    if not photo_url or not public_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="photo_url and public_id are required",
        )

    user.profile_photo_url = photo_url
    user.profile_photo_cloudinary_public_id = public_id
    return await get_me_service(db, user)


async def update_me_service(
    db: AsyncSession, user: User, request: UserMeUpdateRequest
) -> UserMeResponse:
    if request.full_name is not None:
        user.full_name = request.full_name
    if request.phone_number is not None:
        user.phone_number = request.phone_number
    if request.profile_photo_url is not None:
        user.profile_photo_url = str(request.profile_photo_url)
    return await get_me_service(db, user)


async def delete_me_service(db: AsyncSession, user: User) -> None:
    await db.delete(user)


async def list_addresses_service(db: AsyncSession, user: User) -> list[AddressResponse]:
    addresses = await get_addresses_by_user(db, user)
    return [address_response(address) for address in addresses]


async def create_address_service(
    db: AsyncSession, user: User, request: AddressRequest
) -> AddressResponse:
    address_text, latitude, longitude = await resolve_address_input(request)

    if request.is_default:
        await unset_default_addresses(db, user)

    address = Address(user_id=user.id)
    apply_address_request(address, request, latitude=latitude, longitude=longitude)
    address.address_text = address_text
    db.add(address)
    await db.flush()
    return address_response(address)


async def get_address_service(
    db: AsyncSession, user: User, address_id: uuid.UUID
) -> AddressResponse:
    address = await get_address_or_404(db, user, address_id)
    return address_response(address)


async def update_address_service(
    db: AsyncSession,
    user: User,
    address_id: uuid.UUID,
    request: AddressRequest,
) -> AddressResponse:
    address = await get_address_or_404(db, user, address_id)
    address_text, latitude, longitude = await resolve_address_input(request)

    if request.is_default:
        await unset_default_addresses(db, user)

    apply_address_request(address, request, latitude=latitude, longitude=longitude)
    address.address_text = address_text
    return address_response(address)


async def delete_address_service(
    db: AsyncSession, user: User, address_id: uuid.UUID
) -> None:
    address = await get_address_or_404(db, user, address_id)
    await db.delete(address)
