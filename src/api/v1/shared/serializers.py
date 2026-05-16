from src.api.v1.auth.schema import UserSummaryResponse
from src.models.auth import User


def build_user_summary(user: User) -> UserSummaryResponse:
    return UserSummaryResponse(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_onboarded=user.is_onboarded,
    )
