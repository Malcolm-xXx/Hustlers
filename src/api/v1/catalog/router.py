from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.shared.schema import PresignedUploadURLResponse
from src.api.v1.catalog.schema import (
    CategoryResponse,
    CursorPageResponse,
    ProductCardResponse,
    ProductCreateRequest,
    ProductDetailResponse,
    ProductImageResponse,
    ProductImageUploadRequest,
    ProductTagRequest,
    ProductTagResponse,
    ProductTagUpsertRequest,
    ProductUpdateRequest,
    SaleCampaignCreateRequest,
    SaleCampaignResponse,
    SaleCampaignStatusRequest,
    SaleCampaignUpdateRequest,
    SellerTagResponse,
    SellerTagUpsertRequest,
    TagResponse,
    TagScope,
)
from src.api.v1.catalog.service import (
    add_product_tag_service,
    create_product_service,
    create_product_image_service,
    create_sale_campaign_service,
    delete_product_service,
    delete_product_image_service,
    delete_sale_campaign_service,
    generate_product_image_upload_url_service,
    get_product_service,
    get_product_image_service,
    get_sale_campaign_service,
    list_categories_service,
    list_my_products_service,
    list_my_seller_tags_service,
    list_product_images_service,
    list_product_tags_service,
    list_products_service,
    list_sale_campaigns_service,
    list_seller_products_service,
    list_tags_service,
    remove_product_tag_service,
    update_product_service,
    update_sale_campaign_service,
    update_sale_campaign_status_service,
    upsert_my_seller_tags_service,
    upsert_product_tags_service,
)
from src.core.database import get_db
from src.utils.permissions import get_buyer_actor, get_seller_actor

router = APIRouter()


@router.get("/categories/", response_model=list[CategoryResponse])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await list_categories_service(db, current_user)


@router.get("/tags/", response_model=list[TagResponse])
async def list_tags(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    scope: Annotated[TagScope, Query()] = "product",
):
    return await list_tags_service(db, current_user, scope)


@router.get("/me/tags/", response_model=list[SellerTagResponse])
async def list_my_tags(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await list_my_seller_tags_service(db, current_user)


@router.put("/me/tags/", response_model=list[SellerTagResponse])
async def update_my_tags(
    request: SellerTagUpsertRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await upsert_my_seller_tags_service(db, current_user, request)


@router.get("/products/", response_model=CursorPageResponse[ProductCardResponse])
async def list_products(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=10, ge=1, le=100),
    search: str = Query(default=""),
    category: str = Query(default=""),
    seller_id: str = Query(default=""),
    on_sale: bool | None = Query(default=None),
    in_stock: bool | None = Query(default=None),
    min_price: Decimal | None = Query(default=None),
    max_price: Decimal | None = Query(default=None),
    sort: str = Query(default="latest"),
):
    return await list_products_service(
        db,
        current_user,
        cursor=cursor,
        limit=limit,
        search=search,
        category=category,
        seller_id=seller_id,
        on_sale=on_sale,
        in_stock=in_stock,
        min_price=min_price,
        max_price=max_price,
        sort=sort,
    )


@router.post("/products/", response_model=ProductDetailResponse, status_code=201)
async def create_product(
    request: ProductCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await create_product_service(db, current_user, request)


@router.get("/products/{product_id}/", response_model=ProductDetailResponse)
async def get_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await get_product_service(
        db,
        current_user,
        product_id,
    )


@router.patch("/products/{product_id}/", response_model=ProductDetailResponse)
async def update_product(
    product_id: UUID,
    request: ProductUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await update_product_service(db, current_user, product_id, request)


@router.delete("/products/{product_id}/", status_code=204)
async def delete_product(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    await delete_product_service(db, current_user, product_id)


@router.get(
    "/sellers/{seller_id}/products/",
    response_model=CursorPageResponse[ProductCardResponse],
)
async def list_seller_products(
    seller_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    category: str = Query(default=""),
    search: str = Query(default=""),
):
    return await list_seller_products_service(
        db,
        current_user,
        seller_id,
        cursor=cursor,
        limit=limit,
        category=category,
        search=search,
    )


@router.get("/me/products/", response_model=CursorPageResponse[ProductCardResponse])
async def list_my_products(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    status: str = Query(default=""),
    category: str = Query(default=""),
    search: str = Query(default=""),
):
    return await list_my_products_service(
        db,
        current_user,
        cursor=cursor,
        limit=limit,
        status_filter=status,
        category=category,
        search=search,
    )


@router.get(
    "/products/{product_id}/images/upload-url/",
    response_model=PresignedUploadURLResponse,
)
async def get_product_image_upload_url(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await generate_product_image_upload_url_service(
        db,
        current_user,
        product_id,
    )


@router.post(
    "/products/{product_id}/images/",
    response_model=ProductImageResponse,
    status_code=201,
)
async def create_product_image(
    product_id: UUID,
    request: ProductImageUploadRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await create_product_image_service(
        db,
        current_user,
        product_id,
        request.image_url,
        request.public_id,
        is_primary=request.is_primary,
        sort_order=request.sort_order,
    )


@router.get("/products/{product_id}/images/", response_model=list[ProductImageResponse])
async def list_product_images(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await list_product_images_service(db, current_user, product_id)


@router.get(
    "/products/{product_id}/images/{image_id}/", response_model=ProductImageResponse
)
async def get_product_image(
    product_id: UUID,
    image_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    return await get_product_image_service(db, product_id, image_id)


@router.delete("/products/{product_id}/images/{image_id}/", status_code=204)
async def delete_product_image(
    product_id: UUID,
    image_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    await delete_product_image_service(db, current_user, product_id, image_id)


@router.get("/products/{product_id}/tags/", response_model=list[ProductTagResponse])
async def list_product_tags(
    product_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await list_product_tags_service(db, current_user, product_id)


@router.put("/products/{product_id}/tags/", response_model=list[ProductTagResponse])
async def update_product_tags(
    product_id: UUID,
    request: ProductTagUpsertRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await upsert_product_tags_service(db, current_user, product_id, request)


@router.post("/products/{product_id}/tags/", response_model=ProductTagResponse)
async def add_product_tag(
    product_id: UUID,
    request: ProductTagRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await add_product_tag_service(db, current_user, product_id, request)


@router.delete("/products/{product_id}/tags/{tag_id}/", status_code=204)
async def remove_product_tag(
    product_id: UUID,
    tag_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    await remove_product_tag_service(db, current_user, product_id, tag_id)


@router.get("/sale-campaigns/", response_model=CursorPageResponse[SaleCampaignResponse])
async def list_sale_campaigns(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    status: str = Query(default=""),
):
    return await list_sale_campaigns_service(
        db,
        current_user,
        cursor=cursor,
        limit=limit,
        status_filter=status,
    )


@router.post("/sale-campaigns/", response_model=SaleCampaignResponse, status_code=201)
async def create_sale_campaign(
    request: SaleCampaignCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await create_sale_campaign_service(db, current_user, request)


@router.get("/sale-campaigns/{campaign_id}/", response_model=SaleCampaignResponse)
async def get_sale_campaign(
    campaign_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await get_sale_campaign_service(db, current_user, campaign_id)


@router.patch("/sale-campaigns/{campaign_id}/", response_model=SaleCampaignResponse)
async def update_sale_campaign(
    campaign_id: UUID,
    request: SaleCampaignUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await update_sale_campaign_service(db, current_user, campaign_id, request)


@router.delete("/sale-campaigns/{campaign_id}/", status_code=204)
async def delete_sale_campaign(
    campaign_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    await delete_sale_campaign_service(db, current_user, campaign_id)


@router.post(
    "/sale-campaigns/{campaign_id}/status/", response_model=SaleCampaignResponse
)
async def update_sale_campaign_status(
    campaign_id: UUID,
    request: SaleCampaignStatusRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await update_sale_campaign_status_service(
        db,
        current_user,
        campaign_id,
        request,
    )
