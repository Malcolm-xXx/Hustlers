from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.core.database import get_db
from src.models.auth import User
from src.utils.permissions import (
    get_buyer_actor,
    get_buyer_user,
    get_seller_actor,
    get_seller_user,
)


@dataclass
class AuthenticatedContextValue:
    db: AsyncSession
    user: User


@dataclass
class AuthenticatedActorContextValue:
    db: AsyncSession
    user: AuthenticatedActor


DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[AuthenticatedActor, Depends(get_buyer_actor)]
SellerUser = Annotated[AuthenticatedActor, Depends(get_seller_actor)]


async def get_authenticated_context(
    db: DbSession,
    user: Annotated[User, Depends(get_buyer_user)],
) -> AuthenticatedContextValue:
    return AuthenticatedContextValue(db=db, user=user)


async def get_authenticated_actor_context(
    db: DbSession,
    user: CurrentUser,
) -> AuthenticatedActorContextValue:
    return AuthenticatedActorContextValue(db=db, user=user)


async def get_seller_context(
    db: DbSession,
    user: Annotated[User, Depends(get_seller_user)],
) -> AuthenticatedContextValue:
    return AuthenticatedContextValue(db=db, user=user)


AuthenticatedContext = Annotated[
    AuthenticatedContextValue, Depends(get_authenticated_context)
]
AuthenticatedActorContext = Annotated[
    AuthenticatedActorContextValue, Depends(get_authenticated_actor_context)
]
SellerContext = Annotated[AuthenticatedContextValue, Depends(get_seller_context)]
