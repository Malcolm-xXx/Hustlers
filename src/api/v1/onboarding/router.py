from fastapi import APIRouter

from src.api.v1.onboarding.schema import (
    OnboardingCompleteRequest,
    OnboardingStatusResponse,
)
from src.api.v1.onboarding.service import (
    complete_onboarding_step_service,
    get_onboarding_status_service,
)
from src.utils.dependencies import AuthenticatedContext

router = APIRouter()


@router.get("/status/", response_model=OnboardingStatusResponse)
async def get_onboarding_status(
    auth_context: AuthenticatedContext,
):
    return await get_onboarding_status_service(auth_context.db, auth_context.user)


@router.post("/complete/", response_model=OnboardingStatusResponse)
async def complete_onboarding_step(
    request: OnboardingCompleteRequest,
    auth_context: AuthenticatedContext,
):
    return await complete_onboarding_step_service(
        auth_context.db,
        auth_context.user,
        request,
    )
