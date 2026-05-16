from typing import Annotated

from pydantic import BaseModel, Field, model_validator

from src.utils.response import ResponseModel


class OnboardingCompleteRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    address_text: str | None = Field(default=None, max_length=1000)
    latitude: Annotated[float | None, Field(ge=-90, le=90)] = None
    longitude: Annotated[float | None, Field(ge=-180, le=180)] = None
    onboarding_data: dict[str, object] | None = None

    @model_validator(mode="after")
    def validate_location_payload(self):
        has_address_text = bool(self.address_text and self.address_text.strip())
        has_coords = self.latitude is not None and self.longitude is not None

        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Both latitude and longitude must be provided together.")

        if not has_address_text and not has_coords:
            raise ValueError(
                "Provide either address_text or both latitude and longitude."
            )

        return self


class OnboardingStatusResponse(ResponseModel):
    is_onboarded: bool
    role: str
    default_delivery_address: dict[str, object] | None = None
    onboarding_data: dict[str, object] = Field(default_factory=dict)
    next_step: str | None = None


class OnboardingCompleteResponse(ResponseModel):
    detail: str
    user: dict[str, object]
