from __future__ import annotations

from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Query

from src.api.v1.discovery.schema import (
    DiscoverySearchResponse,
    FavoriteProductCreateRequest,
    FavoriteSellerCreateRequest,
    LocationPageResponse,
    ProductCardResponse,
    ProductPageResponse,
    SearchType,
    SellerCardResponse,
    SellerPageResponse,
)
from src.api.v1.discovery.service import (
    add_favorite_product_service,
    add_favorite_seller_service,
    list_favorite_products_service,
    list_favorite_sellers_service,
    list_items_service,
    list_locations_service,
    list_sellers_service,
    remove_favorite_product_service,
    remove_favorite_seller_service,
    search_service,
)
from src.utils.dependencies import AuthenticatedActorContext

router = APIRouter()


@router.get("/sellers/", response_model=SellerPageResponse)
async def list_sellers(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    filter_: str | None = Query(default=None, alias="filter"),
    distance: Decimal | None = Query(default=None, ge=0),
    address_id: UUID | None = Query(default=None),
    latitude: float | None = Query(default=None),
    longitude: float | None = Query(default=None),
):
    return await list_sellers_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        search_query=search,
        filter_key=filter_,
        distance=distance,
        address_id=address_id,
        latitude=latitude,
        longitude=longitude,
    )


@router.get("/items/", response_model=ProductPageResponse)
async def list_discovery_items(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None),
    category: str | None = Query(default=None),
    filter_: str | None = Query(default=None, alias="filter"),
    distance: Decimal | None = Query(default=None, ge=0),
    address_id: UUID | None = Query(default=None),
    latitude: float | None = Query(default=None),
    longitude: float | None = Query(default=None),
):
    return await list_items_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        search_query=search,
        category_key=category,
        filter_key=filter_,
        distance=distance,
        address_id=address_id,
        latitude=latitude,
        longitude=longitude,
    )


@router.get("/search/", response_model=DiscoverySearchResponse)
async def search(
    auth_context: AuthenticatedActorContext,
    q: str = Query(..., min_length=1),
    search_type: SearchType = Query(default=SearchType.ALL, alias="type"),
    category: str | None = Query(default=None),
    favorites_only: bool = Query(default=False),
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    distance: Decimal | None = Query(default=None, ge=0),
    address_id: UUID | None = Query(default=None),
    latitude: float | None = Query(default=None),
    longitude: float | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await search_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        query=q,
        search_type=search_type,
        category_key=category,
        favorites_only=favorites_only,
        min_price=min_price,
        max_price=max_price,
        distance=distance,
        address_id=address_id,
        latitude=latitude,
        longitude=longitude,
    )


@router.get("/locations/", response_model=LocationPageResponse)
async def list_locations(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    q: str | None = Query(default=None),
    distance: Decimal | None = Query(default=None, ge=0),
    address_id: UUID | None = Query(default=None),
    latitude: float | None = Query(default=None),
    longitude: float | None = Query(default=None),
):
    return await list_locations_service(
        auth_context.db,
        auth_context.user,
        cursor,
        limit,
        query=q,
        distance=distance,
        address_id=address_id,
        latitude=latitude,
        longitude=longitude,
    )


@router.get("/favorites/sellers/", response_model=SellerPageResponse)
async def list_favorite_sellers(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_favorite_sellers_service(
        auth_context.db, auth_context.user, cursor, limit
    )


@router.post("/favorites/sellers/", response_model=SellerCardResponse, status_code=201)
async def add_favorite_seller(
    request: FavoriteSellerCreateRequest,
    auth_context: AuthenticatedActorContext,
):
    return await add_favorite_seller_service(
        auth_context.db, auth_context.user, request
    )


@router.delete("/favorites/sellers/{seller_id}/", status_code=204)
async def remove_favorite_seller(
    seller_id: UUID,
    auth_context: AuthenticatedActorContext,
):
    await remove_favorite_seller_service(auth_context.db, auth_context.user, seller_id)


@router.get("/favorites/products/", response_model=ProductPageResponse)
async def list_favorite_products(
    auth_context: AuthenticatedActorContext,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_favorite_products_service(
        auth_context.db, auth_context.user, cursor, limit
    )


@router.post(
    "/favorites/products/", response_model=ProductCardResponse, status_code=201
)
async def add_favorite_product(
    request: FavoriteProductCreateRequest,
    auth_context: AuthenticatedActorContext,
):
    return await add_favorite_product_service(
        auth_context.db, auth_context.user, request
    )


@router.delete("/favorites/products/{product_id}/", status_code=204)
async def remove_favorite_product(
    product_id: UUID,
    auth_context: AuthenticatedActorContext,
):
    await remove_favorite_product_service(
        auth_context.db, auth_context.user, product_id
    )
