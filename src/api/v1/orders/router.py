from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.carts.schema import CartResponse
from src.api.v1.orders.schema import (
    AdjustmentDecisionRequest,
    AlternativeDecisionRequest,
    BuyerOrdersSummaryResponse,
    CheckoutPreviewRequest,
    CheckoutPreviewResponse,
    CheckoutRequest,
    CheckoutResponse,
    OrderAdjustmentRequest,
    OrderComplaintCreateRequest,
    OrderComplaintResultResponse,
    OrderDetailResponse,
    OrderItemAlternativeRequest,
    OrderItemCancelRequest,
    OrderPageResponse,
    OrderReviewCreateRequest,
    OrderReviewResultResponse,
    OrderStatusResponse,
)
from src.api.v1.orders.service import (
    cancel_order_item_service,
    checkout_service,
    create_item_adjustment_service,
    create_item_alternative_service,
    decide_adjustment_service,
    decide_alternative_service,
    file_complaint_service,
    get_buyer_orders_summary_service,
    get_order_service,
    get_order_status_service,
    list_buyer_history_orders_service,
    list_buyer_live_orders_service,
    list_seller_active_orders_service,
    list_seller_history_orders_service,
    preview_checkout_service,
    reorder_service,
    submit_review_service,
)
from src.core.database import get_db
from src.utils.permissions import get_buyer_actor, get_seller_actor

router = APIRouter()


@router.post("/preview/", response_model=CheckoutPreviewResponse)
async def preview_checkout(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    request: CheckoutPreviewRequest | None = None,
):
    return await preview_checkout_service(db, current_user, request)


@router.post("/checkout/", response_model=CheckoutResponse)
async def checkout(
    request: CheckoutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await checkout_service(db, current_user, request)


@router.get("/buyer/live/", response_model=OrderPageResponse)
async def list_buyer_live_orders(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_buyer_live_orders_service(
        db,
        current_user,
        cursor,
        limit,
    )


@router.get("/buyer/history/", response_model=OrderPageResponse)
async def list_buyer_history_orders(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_buyer_history_orders_service(
        db,
        current_user,
        cursor,
        limit,
    )


@router.get("/buyer/summary/", response_model=BuyerOrdersSummaryResponse)
async def get_buyer_orders_summary(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
    range_: str = Query(default="month", alias="range"),
):
    return await get_buyer_orders_summary_service(
        db,
        current_user,
        range_.strip().lower(),
    )


@router.get("/seller/active/", response_model=OrderPageResponse)
async def list_seller_active_orders(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_seller_active_orders_service(
        db,
        current_user,
        cursor,
        limit,
    )


@router.get("/seller/history/", response_model=OrderPageResponse)
async def list_seller_history_orders(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
):
    return await list_seller_history_orders_service(
        db,
        current_user,
        cursor,
        limit,
    )


@router.get("/{order_id}/", response_model=OrderDetailResponse)
async def get_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await get_order_service(db, current_user, order_id)


@router.get("/{order_id}/status/", response_model=OrderStatusResponse)
async def get_order_status(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await get_order_status_service(db, current_user, order_id)


@router.post("/{order_id}/items/{item_id}/cancel/", response_model=OrderDetailResponse)
async def cancel_order_item(
    order_id: UUID,
    item_id: UUID,
    request: OrderItemCancelRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await cancel_order_item_service(
        db,
        current_user,
        order_id,
        item_id,
        request,
    )


@router.post(
    "/{order_id}/items/{item_id}/alternatives/",
    response_model=OrderDetailResponse,
    status_code=201,
)
async def create_item_alternative(
    order_id: UUID,
    item_id: UUID,
    request: OrderItemAlternativeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await create_item_alternative_service(
        db,
        current_user,
        order_id,
        item_id,
        request,
    )


@router.post(
    "/{order_id}/alternatives/{alternative_id}/decision/",
    response_model=OrderDetailResponse,
)
async def decide_alternative(
    order_id: UUID,
    alternative_id: UUID,
    request: AlternativeDecisionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await decide_alternative_service(
        db,
        current_user,
        order_id,
        alternative_id,
        request,
    )


@router.post(
    "/{order_id}/items/{item_id}/adjustments/",
    response_model=OrderDetailResponse,
    status_code=201,
)
async def create_item_adjustment(
    order_id: UUID,
    item_id: UUID,
    request: OrderAdjustmentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await create_item_adjustment_service(
        db,
        current_user,
        order_id,
        item_id,
        request,
    )


@router.post(
    "/{order_id}/adjustments/{adjustment_id}/decision/",
    response_model=OrderDetailResponse,
)
async def decide_adjustment(
    order_id: UUID,
    adjustment_id: UUID,
    request: AdjustmentDecisionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await decide_adjustment_service(
        db,
        current_user,
        order_id,
        adjustment_id,
        request,
    )


@router.post(
    "/{order_id}/complaint/",
    response_model=OrderComplaintResultResponse,
    status_code=201,
)
async def file_complaint(
    order_id: UUID,
    request: OrderComplaintCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_seller_actor),
):
    return await file_complaint_service(db, current_user, order_id, request)


@router.post(
    "/{order_id}/review/", response_model=OrderReviewResultResponse, status_code=201
)
async def submit_review(
    order_id: UUID,
    request: OrderReviewCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await submit_review_service(db, current_user, order_id, request)


@router.post("/{order_id}/reorder/", response_model=CartResponse, status_code=201)
async def reorder(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_buyer_actor),
):
    return await reorder_service(db, current_user, order_id)
