from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID

from fastapi import Request, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.catalog.queries import (
    ensure_active_sale,
    generate_product_slug,
    load_categories,
    product_owned_by_seller,
    remove_active_sale,
    sale_price_map,
    seller_products,
    seller_profile_for_user,
    sync_seller_catalog_counters,
    sync_stock_status,
    validate_allowed_tags,
    visible_products,
)
from src.api.v1.catalog.schema import (
    CategoryResponse,
    CursorPageResponse,
    ProductCardResponse,
    ProductCreateRequest,
    ProductDetailResponse,
    ProductImageResponse,
    ProductTagRequest,
    ProductTagResponse,
    ProductTagUpsertRequest,
    ProductUpdateRequest,
    SaleCampaignCreateRequest,
    SaleCampaignResponse,
    SaleCampaignStatus,
    SaleCampaignStatusRequest,
    SaleCampaignUpdateRequest,
    SellerTagResponse,
    SellerTagUpsertRequest,
    TagResponse,
    TagScope,
)
from src.api.v1.catalog.utils import (
    best_discounted_price,
    campaign_payload,
    category_payload,
    decode_cursor,
    encode_cursor,
    is_after_cursor,
    match_category,
    normalize_product_sort,
    paginate_items,
    parse_cursor_value,
    product_detail_payload,
    product_image_url,
    product_payload,
    product_sort_config,
    product_tag_payload,
    published_and_available,
    seller_tag_payload,
    tag_payload,
)
from src.core.exceptions import HTTPException
from src.models.catalog import (
    Category,
    Product,
    ProductAvailabilityStatus,
    ProductImage,
    ProductPublishStatus,
    ProductStockStatus,
    ProductTag,
    SaleCampaign,
    SaleCampaignItem,
    SellerTag,
    Tag,
)
from src.utils.images import get_image_provider


async def list_categories_service(
    db: AsyncSession, user: AuthenticatedActor
) -> list[CategoryResponse]:
    result = await db.execute(
        select(Category)
        .where(Category.is_active.is_(True))
        .order_by(Category.display_order, Category.name)
    )
    return [category_payload(category) for category in list(result.scalars().all())]


async def list_tags_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    scope: TagScope,
) -> list[TagResponse]:
    queryset = select(Tag).where(Tag.is_active.is_(True))
    if scope == "seller":
        queryset = queryset.join(SellerTag, SellerTag.tag_id == Tag.id)
    else:  # "product"
        queryset = queryset.join(ProductTag, ProductTag.tag_id == Tag.id)

    result = await db.execute(queryset.order_by(Tag.name))
    return [tag_payload(tag) for tag in list(result.scalars().all())]


async def list_my_seller_tags_service(
    db: AsyncSession, user: AuthenticatedActor
) -> list[SellerTagResponse]:
    seller = await seller_profile_for_user(db, user)
    result = await db.execute(
        select(SellerTag)
        .options(selectinload(SellerTag.tag))
        .where(SellerTag.seller_id == seller.id)
    )
    rows = list(result.scalars().all())
    rows.sort(key=lambda row: row.tag.name)
    return [seller_tag_payload(row) for row in rows]


async def upsert_my_seller_tags_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: SellerTagUpsertRequest,
) -> list[SellerTagResponse]:
    seller = await seller_profile_for_user(db, user)
    requested_tag_ids = list(dict.fromkeys(request.tag_ids))
    await validate_allowed_tags(
        db,
        requested_tag_ids,
    )

    existing_result = await db.execute(
        select(SellerTag)
        .options(selectinload(SellerTag.tag))
        .where(SellerTag.seller_id == seller.id)
    )
    existing_rows = list(existing_result.scalars().all())
    existing_map = {row.tag_id: row for row in existing_rows}
    requested_set = set(requested_tag_ids)
    existing_set = set(existing_map)

    to_delete = existing_set - requested_set
    if to_delete:
        await db.execute(
            delete(SellerTag).where(
                SellerTag.seller_id == seller.id,
                SellerTag.tag_id.in_(to_delete),
            )
        )

    to_create = requested_set - existing_set
    for tag_id in to_create:
        db.add(SellerTag(seller_id=seller.id, tag_id=tag_id))

    await db.flush()
    refreshed = await db.execute(
        select(SellerTag)
        .options(selectinload(SellerTag.tag))
        .where(SellerTag.seller_id == seller.id)
    )
    rows = list(refreshed.scalars().all())
    rows.sort(key=lambda row: row.tag.name)
    return [seller_tag_payload(row) for row in rows]


async def visible_products_payload(
    db: AsyncSession,
    *,
    products: list[Product],
    request: Request | None,
    cursor: str | None,
    limit: int,
    sort: str,
) -> CursorPageResponse[ProductCardResponse]:
    sort_name = normalize_product_sort(sort)
    sort_key, sort_kind, descending, key_fn = product_sort_config(sort_name)
    page_items, total_count, next_cursor, has_more = paginate_items(
        products,
        limit=limit,
        cursor=cursor,
        sort_key=sort_key,
        key_fn=key_fn,
        key_kind=sort_kind,
        descending=descending,
    )
    discounted_price_map = await sale_price_map(
        db, {product.id for product in page_items}
    )
    results = [
        product_payload(
            product,
            request=request,
            discounted_price=discounted_price_map.get(product.id),
        )
        for product in page_items
    ]
    return CursorPageResponse[ProductCardResponse](
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
        results=results,
    )


async def list_products_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    request: Request | None = None,
    cursor: str | None = None,
    limit: int = 20,
    search: str = "",
    category: str = "",
    seller_id: str = "",
    on_sale: bool | None = None,
    in_stock: bool | None = None,
    min_price: Decimal | None = None,
    max_price: Decimal | None = None,
    sort: str = "latest",
) -> CursorPageResponse[ProductCardResponse]:
    search_value = search.strip().lower()
    category_value = category.strip()
    seller_value = seller_id.strip()

    products = await visible_products(
        db,
        search_query=search_value or None,
        in_stock_only=in_stock is True,
        min_price=min_price,
        max_price=max_price,
    )

    if category_value:
        products = [
            product for product in products if match_category(product, category_value)
        ]

    if seller_value:
        products = [
            product for product in products if str(product.seller_id) == seller_value
        ]

    discounted_price_map = await sale_price_map(
        db, {product.id for product in products}
    )
    if on_sale is True:
        products = [
            product
            for product in products
            if discounted_price_map.get(product.id) is not None
        ]

    return await visible_products_payload(
        db,
        products=products,
        request=request,
        cursor=cursor,
        limit=limit,
        sort=sort,
    )


async def create_product_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: ProductCreateRequest,
) -> ProductDetailResponse:
    seller = await seller_profile_for_user(db, user)
    categories = await load_categories(db, request.category_ids, required=True)

    product = Product(
        name=request.name,
        slug=await generate_product_slug(db, seller_id=seller.id, name=request.name),
        description=request.description,
        unit_label=request.unit_label,
        base_price=request.base_price,
        stock_quantity=request.stock_quantity,
        low_stock_threshold=request.low_stock_threshold,
        stock_status=ProductStockStatus(request.stock_status.value),
        publish_status=ProductPublishStatus(request.publish_status.value),
        availability_status=ProductAvailabilityStatus(
            request.availability_status.value
        ),
        shelf_life_text=request.shelf_life_text,
        published_at=datetime.now(timezone.utc)
        if request.publish_status.value == ProductPublishStatus.PUBLISHED.value
        else None,
    )
    product.categories = categories
    db.add(product)
    await db.flush()

    await sync_stock_status(product, preserve_existing=True)
    if (
        request.publish_status.value == ProductPublishStatus.PUBLISHED.value
        and product.published_at is None
    ):
        product.published_at = datetime.now(timezone.utc)

    if request.discounted_price is not None:
        if request.discounted_price >= request.base_price:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "discounted_price": [
                        "discounted_price must be less than base_price."
                    ]
                },
            )
        await ensure_active_sale(
            db,
            product=product,
            discounted_price=request.discounted_price,
            seller=seller,
        )

    await sync_seller_catalog_counters(db, seller)
    await db.flush()

    refreshed = await db.execute(
        select(Product)
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(Product.id == product.id)
    )
    created = refreshed.scalar_one()
    discounted_price = best_discounted_price(created)
    return product_detail_payload(created, discounted_price=discounted_price)


async def get_product_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    *,
    request: Request | None = None,
) -> ProductDetailResponse:
    result = await db.execute(
        select(Product)
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(Product.id == product_id)
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )

    discounted_price = best_discounted_price(product)
    return product_detail_payload(
        product, request=request, discounted_price=discounted_price
    )


async def update_product_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    request: ProductUpdateRequest,
) -> ProductDetailResponse:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    current_values = request.model_dump(exclude_unset=True)

    if "name" in current_values and request.name is not None:
        product.slug = await generate_product_slug(
            db,
            seller_id=seller.id,
            name=request.name,
            product_id=product.id,
        )
        product.name = request.name

    if request.category_ids is not None:
        product.categories = await load_categories(
            db, request.category_ids, required=False
        )

    if request.base_price is not None:
        product.base_price = request.base_price
    if request.unit_label is not None:
        product.unit_label = request.unit_label
    if request.description is not None:
        product.description = request.description
    if request.shelf_life_text is not None:
        product.shelf_life_text = request.shelf_life_text
    if request.stock_quantity is not None:
        product.stock_quantity = request.stock_quantity
    if request.low_stock_threshold is not None:
        product.low_stock_threshold = request.low_stock_threshold
    if request.stock_status is not None:
        product.stock_status = ProductStockStatus(request.stock_status.value)
    if request.availability_status is not None:
        product.availability_status = ProductAvailabilityStatus(
            request.availability_status.value
        )
    if request.publish_status is not None:
        product.publish_status = ProductPublishStatus(request.publish_status.value)
        if (
            product.publish_status == ProductPublishStatus.PUBLISHED
            and product.published_at is None
        ):
            product.published_at = datetime.now(timezone.utc)

    await sync_stock_status(product, preserve_existing=request.stock_status is not None)

    if request.discounted_price is not None:
        if request.base_price is not None:
            base_price = request.base_price
        else:
            base_price = product.base_price
        if request.discounted_price >= base_price:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "discounted_price": [
                        "discounted_price must be less than base_price."
                    ]
                },
            )
    if request.discounted_price is None and "discounted_price" in current_values:
        await remove_active_sale(db, product=product, seller=seller)
    elif request.discounted_price is not None:
        await ensure_active_sale(
            db,
            product=product,
            discounted_price=request.discounted_price,
            seller=seller,
        )

    await sync_seller_catalog_counters(db, seller)
    await db.flush()

    refreshed = await db.execute(
        select(Product)
        .options(
            selectinload(Product.seller),
            selectinload(Product.categories),
            selectinload(Product.images),
            selectinload(Product.product_tags).selectinload(ProductTag.tag),
            selectinload(Product.sale_campaign_items).selectinload(
                SaleCampaignItem.campaign
            ),
        )
        .where(Product.id == product.id)
    )
    updated = refreshed.scalar_one()
    discounted_price = best_discounted_price(updated)
    return product_detail_payload(updated, discounted_price=discounted_price)


async def delete_product_service(
    db: AsyncSession, user: AuthenticatedActor, product_id: UUID
) -> None:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    await db.delete(product)
    await db.flush()
    await sync_seller_catalog_counters(db, seller)


async def list_seller_products_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    seller_id: UUID,
    *,
    request: Request | None = None,
    cursor: str | None = None,
    limit: int = 20,
    category: str = "",
    search: str = "",
) -> CursorPageResponse[ProductCardResponse]:
    products = await seller_products(db, seller_id)
    products = published_and_available(products)

    if category.strip():
        products = [
            product for product in products if match_category(product, category)
        ]
    if search.strip():
        search_value = search.strip().lower()
        products = [
            product
            for product in products
            if search_value in product.name.lower()
            or search_value in (product.description or "").lower()
        ]

    return await visible_products_payload(
        db,
        products=products,
        request=request,
        cursor=cursor,
        limit=limit,
        sort="latest",
    )


async def list_my_products_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    request: Request | None = None,
    cursor: str | None = None,
    limit: int = 20,
    status_filter: str = "",
    category: str = "",
    search: str = "",
) -> CursorPageResponse[ProductCardResponse]:
    seller = await seller_profile_for_user(db, user)
    products = await seller_products(db, seller.id)

    normalized_status = status_filter.strip().lower()
    if normalized_status in {item.value for item in ProductPublishStatus}:
        products = [
            product
            for product in products
            if product.publish_status.value == normalized_status
        ]

    if category.strip():
        products = [
            product for product in products if match_category(product, category)
        ]

    if search.strip():
        search_value = search.strip().lower()
        products = [
            product
            for product in products
            if search_value in product.name.lower()
            or search_value in (product.description or "").lower()
        ]

    sort_key = "updated_at"
    ordered = sorted(
        products, key=lambda product: (product.updated_at, product.id.int), reverse=True
    )
    total_count = len(ordered)
    # Need to import from utils - circular issue, let's just call decode directly
    from src.api.v1.catalog.utils import decode_cursor, parse_cursor_value

    if cursor is not None:
        cursor_sort, cursor_value_raw, cursor_id = decode_cursor(cursor)
        if cursor_sort != sort_key:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid cursor.",
            )
        cursor_value = parse_cursor_value(cursor_value_raw, "datetime")
        ordered = [
            product
            for product in ordered
            if is_after_cursor(
                product.updated_at, product.id, cursor_value, cursor_id, descending=True
            )
        ]

    page = ordered[: limit + 1]
    has_more = len(page) > limit
    page = page[:limit]
    next_cursor = (
        encode_cursor(sort_key, page[-1].updated_at, page[-1].id)
        if has_more and page
        else None
    )

    discounted_price_map = await sale_price_map(db, {product.id for product in page})
    results = [
        product_payload(
            product,
            request=request,
            discounted_price=discounted_price_map.get(product.id),
        )
        for product in page
    ]
    return CursorPageResponse[ProductCardResponse](
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
        results=results,
    )


async def list_product_images_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
) -> list[ProductImageResponse]:
    result = await db.execute(
        select(Product)
        .options(selectinload(Product.images))
        .where(
            Product.id == product_id,
            Product.publish_status == ProductPublishStatus.PUBLISHED,
            Product.availability_status == ProductAvailabilityStatus.AVAILABLE,
        )
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found."
        )

    images = sorted(
        product.images,
        key=lambda image: (not image.is_primary, image.sort_order, image.created_at),
    )
    return [
        ProductImageResponse(
            id=image.id,
            image_url=product_image_url(None, image.image_file_url) or "",
            is_primary=image.is_primary,
            sort_order=image.sort_order,
        )
        for image in images
    ]


async def generate_product_image_upload_url_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
) -> dict:
    """Generate a presigned upload URL for a product image."""

    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)

    provider = get_image_provider()
    presigned_response = await provider.generate_presigned_url(
        folder=f"products/{product.id}",
        file_type="product_image",
        resource_type="image",
        expiration_minutes=15,
    )

    return {
        "upload_url": presigned_response.upload_url,
        "public_id": presigned_response.public_id,
        "signature": presigned_response.signature,
        "api_key": presigned_response.api_key,
        "timestamp": presigned_response.timestamp,
        "expires_in": presigned_response.expires_in,
        "allowed_types": presigned_response.allowed_types,
    }


async def create_product_image_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    image_url: str,
    public_id: str,
    *,
    is_primary: bool = False,
    sort_order: int | None = None,
    request: Request | None = None,
) -> ProductImageResponse:
    """Create a product image record after presigned upload to Cloudinary."""

    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)

    if not image_url or not public_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="image_url and public_id are required",
        )

    if is_primary:
        for existing_image in product.images:
            existing_image.is_primary = False

    product_image = ProductImage(
        product_id=product.id,
        image_file_url=image_url,
        cloudinary_public_id=public_id,
        is_primary=is_primary,
        sort_order=sort_order or 0,
    )
    db.add(product_image)
    await db.flush()
    return ProductImageResponse(
        id=product_image.id,
        image_url=product_image_url(request, product_image.image_file_url)
        or product_image.image_file_url,
        is_primary=product_image.is_primary,
        sort_order=product_image.sort_order,
    )


async def get_product_image_service(
    db: AsyncSession,
    product_id: UUID,
    image_id: UUID,
    *,
    request: Request | None = None,
) -> ProductImageResponse:
    result = await db.execute(
        select(ProductImage)
        .where(ProductImage.product_id == product_id, ProductImage.id == image_id)
        .limit(1)
    )
    product_image = result.scalar_one_or_none()
    if product_image is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product image not found.",
        )
    return ProductImageResponse(
        id=product_image.id,
        image_url=product_image_url(request, product_image.image_file_url)
        or product_image.image_file_url,
        is_primary=product_image.is_primary,
        sort_order=product_image.sort_order,
    )


async def delete_product_image_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    image_id: UUID,
) -> None:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    result = await db.execute(
        select(ProductImage).where(
            ProductImage.product_id == product.id, ProductImage.id == image_id
        )
    )
    product_image = result.scalar_one_or_none()
    if product_image is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product image not found.",
        )
    await db.delete(product_image)
    await db.flush()


async def list_product_tags_service(
    db: AsyncSession, user: AuthenticatedActor, product_id: UUID
) -> list[ProductTagResponse]:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    result = await db.execute(
        select(ProductTag)
        .options(selectinload(ProductTag.tag))
        .where(ProductTag.product_id == product.id)
    )
    rows = list(result.scalars().all())
    rows.sort(key=lambda row: row.tag.name)
    return [product_tag_payload(row) for row in rows]


async def upsert_product_tags_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    request: ProductTagUpsertRequest,
) -> list[ProductTagResponse]:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    requested_tag_ids = list(dict.fromkeys(request.tag_ids))
    await validate_allowed_tags(
        db,
        requested_tag_ids,
    )

    existing_result = await db.execute(
        select(ProductTag)
        .options(selectinload(ProductTag.tag))
        .where(ProductTag.product_id == product.id)
    )
    existing_rows = list(existing_result.scalars().all())
    existing_map = {row.tag_id: row for row in existing_rows}
    requested_set = set(requested_tag_ids)
    existing_set = set(existing_map)

    to_delete = existing_set - requested_set
    if to_delete:
        await db.execute(
            delete(ProductTag).where(
                ProductTag.product_id == product.id,
                ProductTag.tag_id.in_(to_delete),
            )
        )

    to_create = requested_set - existing_set
    for tag_id in to_create:
        db.add(ProductTag(product_id=product.id, tag_id=tag_id))

    await db.flush()
    refreshed = await db.execute(
        select(ProductTag)
        .options(selectinload(ProductTag.tag))
        .where(ProductTag.product_id == product.id)
    )
    rows = list(refreshed.scalars().all())
    rows.sort(key=lambda row: row.tag.name)
    return [product_tag_payload(row) for row in rows]


async def add_product_tag_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    request: ProductTagRequest,
) -> ProductTagResponse:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)

    await validate_allowed_tags(db, [request.tag_id])

    existing_result = await db.execute(
        select(ProductTag)
        .options(selectinload(ProductTag.tag))
        .where(
            ProductTag.product_id == product.id,
            ProductTag.tag_id == request.tag_id,
        )
    )
    existing = existing_result.scalar_one_or_none()
    if existing is not None:
        return product_tag_payload(existing)

    new_product_tag = ProductTag(product_id=product.id, tag_id=request.tag_id)
    db.add(new_product_tag)
    await db.flush()

    refreshed = await db.execute(
        select(ProductTag)
        .options(selectinload(ProductTag.tag))
        .where(ProductTag.id == new_product_tag.id)
    )
    created = refreshed.scalar_one()
    return product_tag_payload(created)


async def remove_product_tag_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    product_id: UUID,
    tag_id: UUID,
) -> None:
    seller = await seller_profile_for_user(db, user)
    product = await product_owned_by_seller(db, product_id, seller.id)
    result = await db.execute(
        select(ProductTag).where(
            ProductTag.product_id == product.id, ProductTag.tag_id == tag_id
        )
    )
    product_tag = result.scalar_one_or_none()
    if product_tag is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product tag not found."
        )
    await db.delete(product_tag)
    await db.flush()


async def list_sale_campaigns_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    *,
    cursor: str | None = None,
    limit: int = 20,
    status_filter: str = "",
) -> CursorPageResponse[SaleCampaignResponse]:
    seller = await seller_profile_for_user(db, user)
    result = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(SaleCampaign.seller_id == seller.id)
    )
    campaigns = list(result.scalars().all())

    normalized_status = status_filter.strip().lower()
    if normalized_status:
        valid_statuses = {item.value for item in SaleCampaignStatus}
        if normalized_status not in valid_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "status": [
                        "Invalid status. Expected one of: scheduled, active, ended, cancelled."
                    ]
                },
            )
        campaigns = [
            campaign
            for campaign in campaigns
            if campaign.status.value == normalized_status
        ]

    sort_key = "created_at"
    ordered = sorted(
        campaigns,
        key=lambda campaign: (campaign.created_at, campaign.id.int),
        reverse=True,
    )
    total_count = len(ordered)
    if cursor is not None:
        cursor_sort, cursor_value_raw, cursor_id = decode_cursor(cursor)
        if cursor_sort != sort_key:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid cursor."
            )
        cursor_value = parse_cursor_value(cursor_value_raw, "datetime")
        ordered = [
            campaign
            for campaign in ordered
            if is_after_cursor(
                campaign.created_at,
                campaign.id,
                cursor_value,
                cursor_id,
                descending=True,
            )
        ]

    page = ordered[: limit + 1]
    has_more = len(page) > limit
    page = page[:limit]
    next_cursor = (
        encode_cursor(sort_key, page[-1].created_at, page[-1].id)
        if has_more and page
        else None
    )
    results = [campaign_payload(campaign) for campaign in page]
    return CursorPageResponse[SaleCampaignResponse](
        count=total_count,
        next_cursor=next_cursor,
        has_more=has_more,
        results=results,
    )


async def create_sale_campaign_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: SaleCampaignCreateRequest,
) -> SaleCampaignResponse:
    seller = await seller_profile_for_user(db, user)
    if request.starts_at >= request.ends_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"ends_at": ["ends_at must be after starts_at."]},
        )

    campaign = SaleCampaign(
        seller_id=seller.id,
        name=request.name,
        campaign_type=request.campaign_type,
        discount_percent=request.discount_percent,
        starts_at=request.starts_at,
        ends_at=request.ends_at,
        status=SaleCampaignStatus.SCHEDULED,
    )
    db.add(campaign)
    await db.flush()

    for product_id in request.product_ids:
        product = await product_owned_by_seller(db, product_id, seller.id)
        discounted_price = product.base_price * (1 - request.discount_percent / 100)
        db.add(
            SaleCampaignItem(
                campaign_id=campaign.id,
                product_id=product_id,
                discounted_price=discounted_price,
            )
        )
    await db.flush()

    result = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(SaleCampaign.id == campaign.id)
    )
    created = result.scalar_one()
    return campaign_payload(created)


async def get_sale_campaign_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    campaign_id: UUID,
) -> SaleCampaignResponse:
    seller = await seller_profile_for_user(db, user)
    result = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(
            SaleCampaign.id == campaign_id,
            SaleCampaign.seller_id == seller.id,
        )
    )
    campaign = result.scalar_one_or_none()
    if campaign is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale campaign not found.",
        )
    return campaign_payload(campaign)


async def update_sale_campaign_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    campaign_id: UUID,
    request: SaleCampaignUpdateRequest,
) -> SaleCampaignResponse:
    seller = await seller_profile_for_user(db, user)

    result = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(
            SaleCampaign.id == campaign_id,
            SaleCampaign.seller_id == seller.id,
        )
    )
    campaign = result.scalar_one_or_none()
    if campaign is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale campaign not found.",
        )

    if request.name is not None:
        campaign.name = request.name
    if request.campaign_type is not None:
        campaign.campaign_type = request.campaign_type
    if request.discount_percent is not None:
        campaign.discount_percent = request.discount_percent
    if request.starts_at is not None:
        campaign.starts_at = request.starts_at
    if request.ends_at is not None:
        campaign.ends_at = request.ends_at

    if request.product_ids is not None:
        existing_ids = {item.product_id for item in campaign.items}
        requested_ids = set(request.product_ids)

        to_delete = existing_ids - requested_ids
        if to_delete:
            await db.execute(
                delete(SaleCampaignItem).where(
                    SaleCampaignItem.campaign_id == campaign.id,
                    SaleCampaignItem.product_id.in_(to_delete),
                )
            )

        for product_id in requested_ids - existing_ids:
            product = await product_owned_by_seller(db, product_id, seller.id)
            discounted_price = product.base_price * (
                1 - campaign.discount_percent / 100
            )
            db.add(
                SaleCampaignItem(
                    campaign_id=campaign.id,
                    product_id=product_id,
                    discounted_price=discounted_price,
                )
            )

    await db.flush()

    refreshed = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(SaleCampaign.id == campaign.id)
    )
    updated = refreshed.scalar_one()
    return campaign_payload(updated)


async def delete_sale_campaign_service(
    db: AsyncSession, user: AuthenticatedActor, campaign_id: UUID
) -> None:
    seller = await seller_profile_for_user(db, user)
    result = await db.execute(
        select(SaleCampaign).where(
            SaleCampaign.id == campaign_id,
            SaleCampaign.seller_id == seller.id,
        )
    )
    campaign = result.scalar_one_or_none()
    if campaign is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale campaign not found.",
        )
    await db.delete(campaign)
    await db.flush()


async def update_sale_campaign_status_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    campaign_id: UUID,
    request: SaleCampaignStatusRequest,
) -> SaleCampaignResponse:
    seller = await seller_profile_for_user(db, user)
    result = await db.execute(
        select(SaleCampaign)
        .options(
            selectinload(SaleCampaign.items).selectinload(SaleCampaignItem.product)
        )
        .where(
            SaleCampaign.id == campaign_id,
            SaleCampaign.seller_id == seller.id,
        )
    )
    campaign = result.scalar_one_or_none()
    if campaign is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale campaign not found.",
        )

    CAMPAIGN_STATUS_MAP = {
        "launch": SaleCampaignStatus.ACTIVE,
        "end": SaleCampaignStatus.ENDED,
        "cancel": SaleCampaignStatus.CANCELLED,
    }
    new_status = CAMPAIGN_STATUS_MAP.get(request.action)
    if new_status is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "action": ["Invalid action. Expected one of: launch, end, cancel."]
            },
        )
    campaign.status = new_status
    await db.flush()
    return campaign_payload(campaign)
