from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, HttpUrl, model_validator

from src.models.auth import UserRole
from src.utils.response import ResponseModel


class CoordinatesResponse(ResponseModel):
    latitude: Annotated[float, Field(ge=-90, le=90)]
    longitude: Annotated[float, Field(ge=-180, le=180)]


class LocationResponse(ResponseModel):
    id: UUID
    name: str
    address_text: str | None = None
    coordinates: CoordinatesResponse


class AddressRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    address_text: str | None = Field(default=None, max_length=1000)
    latitude: Annotated[float | None, Field(ge=-90, le=90)] = None
    longitude: Annotated[float | None, Field(ge=-180, le=180)] = None
    is_default: bool = False

    @model_validator(mode="after")
    def validate_exclusive_input(self):
        has_text = self.address_text is not None and self.address_text.strip()
        has_coords = self.latitude is not None and self.longitude is not None

        if has_text and has_coords:
            raise ValueError("Provide either address_text OR coordinates, not both.")

        if not has_text and not has_coords:
            raise ValueError("Provide either address_text or coordinates.")

        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Both latitude and longitude must be provided together.")

        return self


class AddressResponse(ResponseModel):
    id: UUID
    location: LocationResponse
    is_default: bool
    created_at: datetime


class UserSummaryResponse(ResponseModel):
    id: UUID
    full_name: str
    email: EmailStr
    role: UserRole
    is_onboarded: bool


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=1, max_length=255)
    phone_number: str = Field(min_length=7, max_length=20)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    confirm_password: str = Field(min_length=8, max_length=128)

    @model_validator(mode="after")
    def validate_passwords(self):
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match.")
        return self


class RegisterResponse(ResponseModel):
    id: UUID
    full_name: str
    email: EmailStr
    phone_number: str
    role: UserRole
    is_onboarded: bool
    detail: str
    requires_email_verification: bool


class VerifyEmailOtpRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendEmailOtpRequest(BaseModel):
    email: EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class LoginResponse(ResponseModel):
    access: str
    refresh: str
    user: UserSummaryResponse


class TokenRefreshRequest(BaseModel):
    refresh: str


class TokenRefreshResponse(ResponseModel):
    access: str
    refresh: str


class LogoutRequest(BaseModel):
    access: str
    refresh: str


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=1)


class GoogleLoginResponse(ResponseModel):
    access: str
    refresh: str
    user: UserSummaryResponse
    is_new_user: bool


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetVerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class PasswordResetVerifyOtpResponse(ResponseModel):
    detail: str
    verification_token: str


class PasswordResetConfirmRequest(BaseModel):
    email: EmailStr
    verification_token: str = Field(min_length=20, max_length=255)
    new_password: str = Field(min_length=8, max_length=128)
    confirm_password: str = Field(min_length=8, max_length=128)

    @model_validator(mode="after")
    def validate_passwords(self):
        if self.new_password != self.confirm_password:
            raise ValueError("Passwords do not match.")
        return self


class UserMeResponse(ResponseModel):
    id: UUID
    full_name: str
    email: EmailStr
    phone_number: str | None
    profile_photo_url: HttpUrl | None
    role: UserRole
    is_onboarded: bool
    onboarding_data: dict[str, object]
    default_delivery_address: AddressResponse | None
    saved_addresses: list[AddressResponse]
    created_at: datetime


class UserMeUpdateRequest(BaseModel):
    full_name: str | None = None
    phone_number: str | None = None
    profile_photo_url: HttpUrl | None = None


class ProfilePhotoUploadRequest(BaseModel):
    """Request to finalize a profile photo upload after presigned upload to Cloudinary."""

    photo_url: HttpUrl
    public_id: str
