from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.schema import AddressRequest
from src.api.v1.auth.utils import resolve_address_input
from src.models.auth import Address, User

from .queries import get_default_address
from .schema import OnboardingCompleteRequest, OnboardingStatusResponse
from .utils import serialize_default_address


async def get_onboarding_status_service(
    db: AsyncSession, user: User
) -> OnboardingStatusResponse:
    default_address = await get_default_address(db, user.id)
    serialized_default = (
        serialize_default_address(default_address) if default_address else None
    )

    return OnboardingStatusResponse(
        is_onboarded=user.is_onboarded,
        role=user.role.value,
        default_delivery_address=serialized_default,
        onboarding_data=user.onboarding_data or {},
        next_step=None if user.is_onboarded else "complete_onboarding",
    )


async def complete_onboarding_step_service(
    db: AsyncSession,
    user: User,
    request: OnboardingCompleteRequest,
) -> OnboardingStatusResponse:
    address_request = AddressRequest(
        name=request.name.strip(),
        address_text=request.address_text.strip() if request.address_text else None,
        latitude=request.latitude,
        longitude=request.longitude,
        is_default=True,
    )
    address_text, latitude, longitude = await resolve_address_input(address_request)

    user.full_name = request.name.strip()
    user.is_onboarded = True
    user.onboarding_data = {
        **(user.onboarding_data or {}),
        **(request.onboarding_data or {}),
    }

    default_address = await get_default_address(db, user.id)
    if default_address is None:
        default_address = Address(
            user_id=user.id,
            name="Default delivery address",
            address_text=address_text or "",
            latitude=latitude,
            longitude=longitude,
            is_default=True,
        )
        db.add(default_address)
        await db.flush()
    else:
        default_address.address_text = address_text or ""
        default_address.latitude = latitude
        default_address.longitude = longitude
        default_address.is_default = True

    return await get_onboarding_status_service(db, user)
