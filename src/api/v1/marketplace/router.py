import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.marketplace.schema import (
    DispatchDecisionRequest,
    DispatchDecisionResponse,
    DispatchDetailResponse,
    DispatchSummaryResponse,
    HustleListItemCreateRequest,
    HustleListItemUpdateRequest,
    HustleListPublishRequest,
    HustleListSendRequest,
    HustleListSummaryResponse,
    HustleListUpdateRequest,
    HustleListWithdrawRequest,
    PublishResponse,
    SendResponse,
)
from src.api.v1.marketplace.schema import (
    HustleListDetailResponse,
    HustleListRequest,
    HustleListDispatchStatus,
    HustleListStatus,
)
from src.api.v1.marketplace.service import (
    create_hustle_list_item_service,
    create_hustle_list_service,
    decide_dispatch_service,
    delete_hustle_list_item_service,
    delete_hustle_list_service,
    get_dispatch_service,
    get_hustle_list_service,
    get_marketplace_feed_service,
    list_dispatches_service,
    list_hustle_lists_service,
    publish_hustle_list_service,
    send_hustle_list_service,
    update_hustle_list_item_service,
    update_hustle_list_service,
    withdraw_hustle_list_service,
)
from src.core.database import get_db
from src.utils.permissions import get_buyer_actor, get_seller_actor

router = APIRouter()


@router.get("/lists/", response_model=list[HustleListSummaryResponse])
async def list_hustle_lists(
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
    status: HustleListStatus | None = None,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_hustle_lists_service(
        db,
        user,
        status_filter=status.value if status else None,
        cursor=cursor,
        limit=limit,
    )


@router.post("/lists/", response_model=HustleListDetailResponse, status_code=201)
async def create_hustle_list(
    request: HustleListRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await create_hustle_list_service(db, user, request)


@router.get("/lists/{list_id}/", response_model=HustleListDetailResponse)
async def get_hustle_list(
    list_id: uuid.UUID,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await get_hustle_list_service(db, user, list_id)


@router.patch("/lists/{list_id}/", response_model=HustleListDetailResponse)
async def update_hustle_list(
    list_id: uuid.UUID,
    request: HustleListUpdateRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await update_hustle_list_service(
        db,
        user,
        list_id,
        request,
    )


@router.delete("/lists/{list_id}/", status_code=204)
async def delete_hustle_list(
    list_id: uuid.UUID,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    await delete_hustle_list_service(db, user, list_id)


@router.post(
    "/lists/{list_id}/items/", response_model=HustleListDetailResponse, status_code=201
)
async def create_hustle_list_item(
    list_id: uuid.UUID,
    request: HustleListItemCreateRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await create_hustle_list_item_service(
        db,
        user,
        list_id,
        request,
    )


@router.patch(
    "/lists/{list_id}/items/{item_id}/", response_model=HustleListDetailResponse
)
async def update_hustle_list_item(
    list_id: uuid.UUID,
    item_id: uuid.UUID,
    request: HustleListItemUpdateRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await update_hustle_list_item_service(
        db,
        user,
        list_id,
        item_id,
        request,
    )


@router.post(
    "/lists/{list_id}/items/{item_id}/remove/", response_model=HustleListDetailResponse
)
async def delete_hustle_list_item(
    list_id: uuid.UUID,
    item_id: uuid.UUID,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await delete_hustle_list_item_service(
        db,
        user,
        list_id,
        item_id,
    )


@router.post("/lists/{list_id}/send/", response_model=SendResponse)
async def send_hustle_list(
    list_id: uuid.UUID,
    request: HustleListSendRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await send_hustle_list_service(
        db,
        user,
        list_id,
        request,
    )


@router.post("/lists/{list_id}/publish/", response_model=PublishResponse)
async def publish_hustle_list(
    list_id: uuid.UUID,
    request: HustleListPublishRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await publish_hustle_list_service(
        db,
        user,
        list_id,
        request,
    )


@router.post("/lists/{list_id}/withdraw/", response_model=HustleListDetailResponse)
async def withdraw_hustle_list(
    list_id: uuid.UUID,
    request: HustleListWithdrawRequest,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await withdraw_hustle_list_service(
        db,
        user,
        list_id,
        request,
    )


@router.get("/feed/", response_model=list[HustleListSummaryResponse])
async def get_marketplace_feed(
    user: AuthenticatedActor = Depends(get_seller_actor),
    db: AsyncSession = Depends(get_db),
    place_id: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await get_marketplace_feed_service(
        db,
        user,
        place_id=place_id,
        latitude=latitude,
        longitude=longitude,
        cursor=cursor,
        limit=limit,
    )


@router.get("/dispatches/", response_model=list[DispatchSummaryResponse])
async def list_dispatches(
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
    role: str | None = None,
    status: HustleListDispatchStatus | None = None,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_dispatches_service(
        db,
        user,
        role=role,
        status_filter=status.value if status else None,
        cursor=cursor,
        limit=limit,
    )


@router.get("/dispatches/{dispatch_id}/", response_model=DispatchDetailResponse)
async def get_dispatch(
    dispatch_id: uuid.UUID,
    user: AuthenticatedActor = Depends(get_buyer_actor),
    db: AsyncSession = Depends(get_db),
):
    return await get_dispatch_service(db, user, dispatch_id)


@router.post(
    "/dispatches/{dispatch_id}/decision/", response_model=DispatchDecisionResponse
)
async def decide_dispatch(
    dispatch_id: uuid.UUID,
    request: DispatchDecisionRequest,
    user: AuthenticatedActor = Depends(get_seller_actor),
    db: AsyncSession = Depends(get_db),
):
    return await decide_dispatch_service(
        db,
        user,
        dispatch_id,
        request,
    )
