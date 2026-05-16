from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.ably.schema import AblyTokenResponse
from src.api.v1.auth.utils import AuthenticatedActor
from src.core.ably import create_ably_jwt


async def generate_ably_token_service(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> AblyTokenResponse:
    capability = {
        f"notifications:user-{user.id}": ["subscribe"],
        "messaging:*": ["subscribe"],
    }
    token = create_ably_jwt(
        client_id=str(user.id),
        capability=capability,
        expires_in=3600,
    )
    return AblyTokenResponse(token=token)
