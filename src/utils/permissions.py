from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.queries import get_user_by_id
from src.api.v1.auth.utils import (
    AuthenticatedActor,
    get_current_authenticated_actor,
    require_roles,
)
from src.core.database import get_db
from src.models import UserRole
from src.models.auth import User


def can_do_buyer_actions(user: AuthenticatedActor) -> bool:
    return user.role in (UserRole.BUYER, UserRole.SELLER, UserRole.ADMIN)


def can_do_seller_actions(user: AuthenticatedActor) -> bool:
    return user.role in (UserRole.SELLER, UserRole.ADMIN)


def _create_role_user_dependency(*allowed_roles: UserRole):
    """Factory to create role-based DB-backed user dependencies."""

    async def getter(
        db: AsyncSession = Depends(get_db),
        jwt_payload=Depends(require_roles(*allowed_roles)),
    ) -> User:
        user = await get_user_by_id(db, jwt_payload.user_id)
        if not user:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    return getter


def _create_role_actor_dependency(*allowed_roles: UserRole):
    """Factory to create role-based JWT-backed actor dependencies."""

    async def getter(
        actor: AuthenticatedActor = Depends(get_current_authenticated_actor),
    ) -> AuthenticatedActor:
        if actor.role not in allowed_roles:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return actor

    return getter


get_buyer_user = _create_role_user_dependency(
    UserRole.BUYER, UserRole.SELLER, UserRole.ADMIN
)
get_seller_user = _create_role_user_dependency(UserRole.SELLER, UserRole.ADMIN)
get_admin_user = _create_role_user_dependency(UserRole.ADMIN)

get_buyer_actor = _create_role_actor_dependency(
    UserRole.BUYER, UserRole.SELLER, UserRole.ADMIN
)
get_seller_actor = _create_role_actor_dependency(UserRole.SELLER, UserRole.ADMIN)
get_admin_actor = _create_role_actor_dependency(UserRole.ADMIN)
