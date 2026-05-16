from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.payments.schema import WalletWithTodayResponse
from src.api.v1.sellers.schema import (
    LocationSummary,
    PaginatedHustleListSummaryResponse,
    PaginatedLocationSummaryResponse,
    PaginatedOrderSummaryResponse,
    SellerPresenceResponse,
    SellerPresenceUpdateRequest,
    SellerProfileResponse,
    SellerProfileUpdateRequest,
    SellerServiceAreaCreateRequest,
    ServiceAreaResponse,
)
from src.api.v1.sellers.service import (
    create_service_area_service,
    delete_service_area_service,
    get_my_presence_service,
    get_my_profile_service,
    get_seller_service,
    get_seller_wallet_service,
    list_available_lists_service,
    list_high_demand_areas_service,
    list_seller_active_orders_service,
    list_service_area_options_service,
    list_service_areas_service,
    update_my_presence_service,
    update_my_profile_service,
)
from src.core.database import get_db
from src.models.auth import User
from src.utils.permissions import get_seller_user

router = APIRouter()


@router.get("/me/wallet/", response_model=WalletWithTodayResponse)
async def get_seller_wallet(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await get_seller_wallet_service(db, user)


@router.get("/me/orders/active/", response_model=PaginatedOrderSummaryResponse)
async def list_seller_active_orders(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_seller_active_orders_service(db, user, cursor, limit, request)


@router.get("/me/lists/available/", response_model=PaginatedHustleListSummaryResponse)
async def list_available_lists(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_available_lists_service(db, user, cursor, limit)


@router.get("/me/areas/high-demand/", response_model=list[LocationSummary])
async def list_high_demand_areas(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await list_high_demand_areas_service(db, user)


@router.get("/me/profile/", response_model=SellerProfileResponse)
async def get_my_profile(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await get_my_profile_service(db, user, request)


@router.patch("/me/profile/", response_model=SellerProfileResponse)
async def update_my_profile(
    request: Request,
    request_data: SellerProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await update_my_profile_service(db, user, request_data, request)


@router.get("/me/presence/", response_model=SellerPresenceResponse)
async def get_my_presence(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await get_my_presence_service(db, user)


@router.patch("/me/presence/", response_model=SellerPresenceResponse)
async def update_my_presence(
    request_data: SellerPresenceUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await update_my_presence_service(db, user, request_data)


@router.get("/me/service-areas/", response_model=list[ServiceAreaResponse])
async def list_service_areas(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await list_service_areas_service(db, user)


@router.post("/me/service-areas/", response_model=ServiceAreaResponse, status_code=201)
async def create_service_area(
    request_data: SellerServiceAreaCreateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await create_service_area_service(db, user, request_data)


@router.delete("/me/service-areas/{service_area_id}/", status_code=204)
async def delete_service_area(
    service_area_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    await delete_service_area_service(db, user, service_area_id)


@router.get(
    "/me/service-area-options/", response_model=PaginatedLocationSummaryResponse
)
async def list_service_area_options(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
    search: str | None = None,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_service_area_options_service(db, user, cursor, limit, search)


@router.get("/{seller_id}/", response_model=SellerProfileResponse)
async def get_seller(
    request: Request,
    seller_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_seller_user),
):
    return await get_seller_service(db, user, seller_id, request)
