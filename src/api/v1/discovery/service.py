from __future__ import annotations

import uuid
from decimal import Decimal

from fastapi import status
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.discovery.queries import (
    get_existing_favorite_product,
    get_existing_favorite_seller,
    get_favorite_product_ids,
    get_favorite_product_links,
    get_favorite_seller_ids,
    get_favorite_seller_links,
    get_product_for_favorite,
    get_seller_profile_for_favorite,
    load_locations,
    load_products,
    load_seller_profiles,
    resolve_origin_coordinates,
)
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
from src.api.v1.discovery.utils import (
    filter_by_distance,
    filter_locations,
    filter_products,
    filter_sellers,
    location_card,
    location_distance_map,
    normalize_optional_text,
    paginate_items,
    product_card,
    product_distance_map,
    seller_card,
    seller_distance_map,
)
from src.core.exceptions import HTTPException
from src.models.discovery import FavoriteProduct, FavoriteSeller


async def list_sellers_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    *,
    search_query: str | None = None,
    filter_key: str | None = None,
    distance: Decimal | None = None,
    address_id: uuid.UUID | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> SellerPageResponse:
    _, origin_coordinates = await resolve_origin_coordinates(
        db,
        user.id,
        address_id,
        latitude,
        longitude,
    )

    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)

    sellers = filter_sellers(
        await load_seller_profiles(db),
        search_query=normalize_optional_text(search_query),
        filter_key=normalize_optional_text(filter_key, lower=True),
        favorite_seller_ids=favorite_seller_ids,
    )

    distance_map = await seller_distance_map(db, sellers, origin_coordinates)
    sellers = filter_by_distance(
        sellers,
        distance_map=distance_map,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )

    paginated_sellers, next_cursor, has_more = paginate_items(sellers, cursor, limit)

    return SellerPageResponse(
        items=[
            seller_card(
                seller,
                favorite_seller_ids=favorite_seller_ids,
                distance_km=distance_map.get(seller.id),
            )
            for seller in paginated_sellers
        ],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def list_items_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    *,
    search_query: str | None = None,
    category_key: str | None = None,
    filter_key: str | None = None,
    distance: Decimal | None = None,
    address_id: uuid.UUID | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> ProductPageResponse:
    """List discoverable products for buyers."""

    _, origin_coordinates = await resolve_origin_coordinates(
        db,
        user.id,
        address_id,
        latitude,
        longitude,
    )

    favorite_product_ids = await get_favorite_product_ids(db, user.id)

    products = filter_products(
        await load_products(db),
        search_query=normalize_optional_text(search_query),
        category_key=normalize_optional_text(category_key),
        filter_key=normalize_optional_text(filter_key, lower=True),
        favorite_product_ids=favorite_product_ids,
    )

    distance_map = await product_distance_map(db, products, origin_coordinates)
    products = filter_by_distance(
        products,
        distance_map=distance_map,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )

    paginated_products, next_cursor, has_more = paginate_items(products, cursor, limit)

    return ProductPageResponse(
        items=[product_card(product) for product in paginated_products],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def list_locations_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    *,
    query: str | None = None,
    distance: Decimal | None = None,
    address_id: uuid.UUID | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> LocationPageResponse:
    """List active service-area locations for buyers."""

    _, origin_coordinates = await resolve_origin_coordinates(
        db,
        user.id,
        address_id,
        latitude,
        longitude,
    )

    locations = filter_locations(
        await load_locations(db), query=normalize_optional_text(query)
    )
    distance_map = await location_distance_map(locations, origin_coordinates)
    locations = filter_by_distance(
        locations,
        distance_map=distance_map,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )

    paginated_locations, next_cursor, has_more = paginate_items(
        locations, cursor, limit
    )

    return LocationPageResponse(
        items=[
            location_card(location, distance_km=distance_map.get(location.id))
            for location in paginated_locations
        ],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def search_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
    *,
    query: str,
    search_type: SearchType,
    category_key: str | None = None,
    favorites_only: bool = False,
    min_price: Decimal | None = None,
    max_price: Decimal | None = None,
    distance: Decimal | None = None,
    address_id: uuid.UUID | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> DiscoverySearchResponse:
    """Search across products, sellers, and locations."""

    normalized_query = normalize_optional_text(query)
    if not normalized_query:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"q": ["This field may not be blank."]},
        )

    if min_price is not None and max_price is not None and min_price > max_price:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "max_price": ["max_price must be greater than or equal to min_price."]
            },
        )

    _, origin_coordinates = await resolve_origin_coordinates(
        db,
        user.id,
        address_id,
        latitude,
        longitude,
    )

    favorite_seller_ids = await get_favorite_seller_ids(db, user.id)
    favorite_product_ids = await get_favorite_product_ids(db, user.id)

    products = filter_products(
        await load_products(db),
        search_query=normalized_query,
        category_key=normalize_optional_text(category_key),
        filter_key="favorites" if favorites_only else None,
        favorite_product_ids=favorite_product_ids,
    )
    if min_price is not None:
        products = [product for product in products if product.base_price >= min_price]
    if max_price is not None:
        products = [product for product in products if product.base_price <= max_price]

    sellers = filter_sellers(
        await load_seller_profiles(db),
        search_query=normalized_query,
        filter_key="favorites" if favorites_only else None,
        favorite_seller_ids=favorite_seller_ids,
    )

    locations = filter_locations(await load_locations(db), query=normalized_query)

    product_distances = await product_distance_map(db, products, origin_coordinates)
    seller_distances = await seller_distance_map(db, sellers, origin_coordinates)
    location_distances = await location_distance_map(locations, origin_coordinates)

    products = filter_by_distance(
        products,
        distance_map=product_distances,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )
    sellers = filter_by_distance(
        sellers,
        distance_map=seller_distances,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )
    locations = filter_by_distance(
        locations,
        distance_map=location_distances,
        distance_limit=distance,
        origin_coordinates=origin_coordinates,
    )

    items_type = search_type == SearchType.ITEMS
    sellers_type = search_type == SearchType.SELLERS
    locations_type = search_type == SearchType.LOCATIONS

    paginated_products, product_next_cursor, product_has_more = (
        paginate_items(products, cursor, limit)
        if not sellers_type and not locations_type
        else ([], None, False)
    )
    paginated_sellers, seller_next_cursor, seller_has_more = (
        paginate_items(sellers, cursor, limit)
        if not items_type and not locations_type
        else ([], None, False)
    )
    paginated_locations, location_next_cursor, location_has_more = (
        paginate_items(locations, cursor, limit)
        if not items_type and not sellers_type
        else ([], None, False)
    )

    return DiscoverySearchResponse(
        items=ProductPageResponse(
            items=[product_card(product) for product in paginated_products],
            next_cursor=product_next_cursor,
            has_more=product_has_more,
        ),
        sellers=SellerPageResponse(
            items=[
                seller_card(
                    seller,
                    favorite_seller_ids=favorite_seller_ids,
                    distance_km=seller_distances.get(seller.id),
                )
                for seller in paginated_sellers
            ],
            next_cursor=seller_next_cursor,
            has_more=seller_has_more,
        ),
        locations=LocationPageResponse(
            items=[
                location_card(location, distance_km=location_distances.get(location.id))
                for location in paginated_locations
            ],
            next_cursor=location_next_cursor,
            has_more=location_has_more,
        ),
    )


async def list_favorite_sellers_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> SellerPageResponse:
    """List a buyer's favorite sellers."""

    favorite_links = await get_favorite_seller_links(db, user.id)
    paginated_links, next_cursor, has_more = paginate_items(
        favorite_links, cursor, limit
    )

    _, origin_coordinates = await resolve_origin_coordinates(db, user.id, None)
    favorite_seller_ids = {favorite_link.seller_id for favorite_link in favorite_links}

    sellers = [favorite_link.seller for favorite_link in paginated_links]
    distance_map = await seller_distance_map(db, sellers, origin_coordinates)

    return SellerPageResponse(
        items=[
            seller_card(
                seller,
                favorite_seller_ids=favorite_seller_ids,
                distance_km=distance_map.get(seller.id),
            )
            for seller in sellers
        ],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def add_favorite_seller_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: FavoriteSellerCreateRequest,
) -> SellerCardResponse:
    """Add a seller to the buyer's favorites."""

    seller = await get_seller_profile_for_favorite(db, request.seller_id)
    if seller is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"seller_id": ["Seller not found."]},
        )

    existing_favorite = await get_existing_favorite_seller(db, user.id, seller.id)
    if existing_favorite is None:
        db.add(FavoriteSeller(user_id=user.id, seller_id=seller.id))

    _, origin_coordinates = await resolve_origin_coordinates(db, user.id, None)
    distance_map = await seller_distance_map(db, [seller], origin_coordinates)

    return seller_card(
        seller,
        favorite_seller_ids={seller.id},
        distance_km=distance_map.get(seller.id),
    )


async def remove_favorite_seller_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    seller_id: uuid.UUID,
) -> None:
    """Remove a seller from the buyer's favorites."""

    await db.execute(
        delete(FavoriteSeller).where(
            FavoriteSeller.user_id == user.id,
            FavoriteSeller.seller_id == seller_id,
        )
    )


async def list_favorite_products_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> ProductPageResponse:
    """List a buyer's favorite products."""

    favorite_links = await get_favorite_product_links(db, user.id)
    paginated_links, next_cursor, has_more = paginate_items(
        favorite_links, cursor, limit
    )

    products = [favorite_link.product for favorite_link in paginated_links]

    return ProductPageResponse(
        items=[product_card(product) for product in products],
        next_cursor=next_cursor,
        has_more=has_more,
    )


async def remove_favorite_product_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: uuid.UUID,
) -> None:
    """Remove a product from the buyer's favorites."""

    await db.execute(
        delete(FavoriteProduct).where(
            FavoriteProduct.user_id == user.id,
            FavoriteProduct.product_id == product_id,
        )
    )


async def add_favorite_product_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: FavoriteProductCreateRequest,
) -> ProductCardResponse:
    """Add a product to the buyer's favorites."""

    product = await get_product_for_favorite(db, request.product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"product_id": ["Product not found."]},
        )

    existing_favorite = await get_existing_favorite_product(db, user.id, product.id)
    if existing_favorite is None:
        db.add(FavoriteProduct(user_id=user.id, product_id=product.id))

    return product_card(product)
