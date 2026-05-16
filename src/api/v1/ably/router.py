from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.ably.schema import AblyTokenResponse
from src.api.v1.ably.service import generate_ably_token_service
from src.api.v1.auth.utils import AuthenticatedActor, get_current_authenticated_actor
from src.core.database import get_db

router = APIRouter()


@router.post("/auth/", response_model=AblyTokenResponse)
async def generate_ably_token(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_current_authenticated_actor),
):
    return await generate_ably_token_service(db, current_user)
