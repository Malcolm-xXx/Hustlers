from fastapi import APIRouter, Query

from src.api.v1.analytics.schema import (
    BuyerSpending,
    HotZone,
    SellerInsight,
    ServiceAreaOpportunity,
    TopListing,
    ViewEventCreate,
    ViewEventResponse,
)
from src.api.v1.analytics.service import (
    create_view_event_service,
    get_buyer_spending_service,
    get_seller_hot_zones_service,
    get_seller_overview_service,
    get_seller_top_listings_service,
    get_service_area_opportunities_service,
)
from src.utils.dependencies import CurrentUser, DbSession, SellerUser

router = APIRouter()


@router.get("/seller/overview/", response_model=SellerInsight)
async def get_seller_overview(
    *,
    user: SellerUser,
    db: DbSession,
    range_: str = Query("week", alias="range"),
):
    return await get_seller_overview_service(db, user, range_)


@router.get("/seller/top-listings/", response_model=list[TopListing])
async def get_seller_top_listings(
    *,
    user: SellerUser,
    db: DbSession,
    range_: str = Query("week", alias="range"),
    limit: int = Query(5, ge=1),
):
    return await get_seller_top_listings_service(db, user, range_, limit)


@router.get("/seller/hot-zones/", response_model=list[HotZone])
async def get_seller_hot_zones(
    *,
    user: SellerUser,
    db: DbSession,
    range_: str = Query("week", alias="range"),
    limit: int = Query(5, ge=1),
):
    return await get_seller_hot_zones_service(db, user, range_, limit)


@router.get(
    "/seller/service-area-opportunities/", response_model=list[ServiceAreaOpportunity]
)
async def get_service_area_opportunities(
    *,
    user: SellerUser,
    db: DbSession,
    limit: int = Query(10, ge=1),
):
    return await get_service_area_opportunities_service(db, user, limit)


@router.get("/buyer/spending/", response_model=BuyerSpending)
async def get_buyer_spending(
    *,
    user: CurrentUser,
    db: DbSession,
    range_: str = Query("month", alias="range"),
):
    return await get_buyer_spending_service(db, user, range_)


@router.post("/events/views/", response_model=ViewEventResponse, status_code=202)
async def create_view_event(
    request: ViewEventCreate,
    *,
    user: CurrentUser,
    db: DbSession,
):
    return await create_view_event_service(db, user, request)
