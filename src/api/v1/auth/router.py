import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

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
    ProfilePhotoUploadRequest,
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
    AuthenticatedActor,
    get_current_authenticated_actor,
    get_current_authenticated_user,
)
from src.api.v1.auth.service import (
    confirm_password_reset_service,
    create_address_service,
    delete_address_service,
    delete_me_service,
    generate_profile_photo_upload_url_service,
    get_address_service,
    get_me_service,
    google_login_service,
    list_addresses_service,
    login_service,
    logout_service,
    refresh_tokens_service,
    register_service,
    request_password_reset_service,
    resend_email_otp_service,
    update_address_service,
    update_me_service,
    update_profile_photo_from_url_service,
    verify_email_otp_service,
    verify_password_reset_otp_service,
)
from src.api.v1.shared.schema import PresignedUploadURLResponse
from src.core.database import get_db
from src.models.auth import User


router = APIRouter()


@router.post("/register/", response_model=RegisterResponse, status_code=201)
async def register(
    request: RegisterRequest,
    db=Depends(get_db),
):
    return await register_service(db, request)


@router.post("/register/verify-email-otp/", status_code=200)
async def verify_email_otp(
    request: VerifyEmailOtpRequest,
    db=Depends(get_db),
):
    return await verify_email_otp_service(db, request)


@router.post("/register/resend-email-otp/", status_code=200)
async def resend_email_otp(
    request: ResendEmailOtpRequest,
    db=Depends(get_db),
):
    return await resend_email_otp_service(db, request)


@router.post("/login/", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    db=Depends(get_db),
):
    return await login_service(db, request)


@router.post("/token/refresh/", response_model=TokenRefreshResponse)
async def refresh_token(
    request: TokenRefreshRequest,
    db=Depends(get_db),
):
    return await refresh_tokens_service(db, request)


@router.post("/logout/", status_code=205)
async def logout(
    request: LogoutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_current_authenticated_actor),
):
    del current_user
    return await logout_service(db, request)


@router.post("/google/", response_model=GoogleLoginResponse)
async def google_login(
    request: GoogleLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    return await google_login_service(db, request)


@router.post("/password/reset/request/", status_code=200)
async def password_reset_request(
    request: PasswordResetRequest,
    db: AsyncSession = Depends(get_db),
):
    return await request_password_reset_service(db, request)


@router.post(
    "/password/reset/verify-otp/", response_model=PasswordResetVerifyOtpResponse
)
async def password_reset_verify_otp(
    request: PasswordResetVerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    return await verify_password_reset_otp_service(db, request)


@router.post("/password/reset/confirm/", status_code=200)
async def password_reset_confirm(
    request: PasswordResetConfirmRequest,
    db: AsyncSession = Depends(get_db),
):
    return await confirm_password_reset_service(db, request)


@router.get("/me/", response_model=UserMeResponse)
async def get_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await get_me_service(db, current_user)


@router.get("/me/profile-photo/upload-url/", response_model=PresignedUploadURLResponse)
async def get_profile_photo_upload_url(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await generate_profile_photo_upload_url_service(db, current_user)


@router.post("/me/profile-photo/", response_model=UserMeResponse)
async def update_profile_photo(
    photo_request: ProfilePhotoUploadRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await update_profile_photo_from_url_service(
        db,
        current_user,
        str(photo_request.photo_url),
        photo_request.public_id,
    )


@router.patch("/me/", response_model=UserMeResponse)
async def update_me(
    request: UserMeUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await update_me_service(db, current_user, request)


@router.delete("/me/", status_code=204)
async def delete_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    await delete_me_service(db, current_user)


@router.get("/me/addresses/", response_model=list[AddressResponse])
async def list_addresses(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await list_addresses_service(db, current_user)


@router.post("/me/addresses/", response_model=AddressResponse, status_code=201)
async def create_address(
    request: AddressRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await create_address_service(db, current_user, request)


@router.get("/me/addresses/{address_id}/", response_model=AddressResponse)
async def get_address(
    address_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await get_address_service(db, current_user, address_id)


@router.patch("/me/addresses/{address_id}/", response_model=AddressResponse)
async def update_address(
    address_id: uuid.UUID,
    request: AddressRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    return await update_address_service(
        db,
        current_user,
        address_id,
        request,
    )


@router.delete("/me/addresses/{address_id}/", status_code=204)
async def delete_address(
    address_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_authenticated_user),
):
    await delete_address_service(db, current_user, address_id)
