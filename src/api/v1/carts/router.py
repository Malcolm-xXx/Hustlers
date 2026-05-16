"""NOTE: Carts Models stash here and there's only one active cart per user.
And they can only add or delete from the acive cart (or stash)"""

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.carts.schema import (
    CartItemRequest,
    CartItemUpdateRequest,
    CartResponse,
    SavedCartsPageResponse,
)
from src.api.v1.carts.service import (
    create_current_cart_item_service,
    delete_current_cart_item_service,
    delete_saved_cart_service,
    empty_current_cart_service,
    get_current_cart_service,
    list_saved_carts_service,
    restore_saved_cart_service,
    save_cart_service,
    update_current_cart_item_service,
)
from src.core.database import get_db
from src.utils.permissions import get_buyer_actor

router = APIRouter()


@router.get("/current/", response_model=CartResponse)
async def get_current_cart(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await get_current_cart_service(db, current_user)


@router.post("/current/items/", response_model=CartResponse, status_code=201)
async def create_current_cart_item(
    request: CartItemRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await create_current_cart_item_service(db, current_user, request)


@router.patch("/current/items/{item_id}/", response_model=CartResponse)
async def update_current_cart_item(
    item_id: uuid.UUID,
    request: CartItemUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await update_current_cart_item_service(
        db,
        current_user,
        item_id,
        request,
    )


@router.delete("/current/items/{item_id}/", response_model=CartResponse)
async def delete_current_cart_item(
    item_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await delete_current_cart_item_service(db, current_user, item_id)


@router.post("/current/empty/", response_model=CartResponse)
async def empty_current_cart(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await empty_current_cart_service(db, current_user)


@router.post("/current/save/", response_model=CartResponse)
async def save_cart(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await save_cart_service(db, current_user)


@router.get("/saved/", response_model=SavedCartsPageResponse)
async def list_saved_carts(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_saved_carts_service(
        db,
        current_user,
        cursor,
        limit,
    )


@router.post("/saved/{cart_id}/restore/", response_model=CartResponse)
async def restore_saved_cart(
    cart_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await restore_saved_cart_service(db, current_user, cart_id)


@router.delete("/saved/{cart_id}/", status_code=204)
async def delete_saved_cart(
    cart_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    await delete_saved_cart_service(db, current_user, cart_id)
