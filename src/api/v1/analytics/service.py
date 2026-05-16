from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.analytics.schema import (
    BuyerSpending,
    EntityType,
    HotZone,
    SellerInsight,
    ServiceAreaOpportunity,
    TopListing,
    ViewEventCreate,
    ViewEventResponse,
)
from src.api.v1.shared.utils.currency import format_money
from src.core.exceptions import HTTPException
from src.models.analytics import (
    ListingViewEvent,
    LocationDailyMetric,
    ProductDailyMetric,
    SellerDailyMetric,
)
from src.models.catalog import (
    Category,
    Product,
    ProductStockStatus,
    product_categories,
)
from src.models.marketplace import ServiceAreaLocation
from src.models.orders import Order, OrderSourceType, OrderStatus
from src.models.sellers import SellerProfile
from src.utils.permissions import can_do_buyer_actions, can_do_seller_actions


def format_percent(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.01')):.2f}"


def format_rating(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.01')):.2f}"


def format_success_rate(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.0001')):.4f}"


def current_time() -> datetime:
    return datetime.now(timezone.utc)


def range_start(range_value: str) -> datetime:
    now = current_time()
    if range_value == "today":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if range_value == "week":
        return now - timedelta(days=7)
    if range_value == "month":
        return now - timedelta(days=30)

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail={"range": ["Invalid range. Expected today, week, or month."]},
    )


def previous_range_start(range_value: str, start: datetime) -> datetime:
    if range_value == "today":
        return start - timedelta(days=1)
    if range_value == "week":
        return start - timedelta(days=7)
    if range_value == "month":
        return start - timedelta(days=30)

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail={"range": ["Invalid range. Expected today, week, or month."]},
    )


def percentage_change(current: Decimal, previous: Decimal) -> str:
    if previous == 0:
        return format_percent(Decimal("100.00") if current else Decimal("0.00"))

    change = ((current - previous) / previous) * Decimal("100")
    return format_percent(change)


async def seller_profile_for_user(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> SellerProfile | None:
    result = await db.execute(
        select(SellerProfile).where(SellerProfile.user_id == user.id)
    )
    return result.scalar_one_or_none()


def product_payload(row: object) -> dict[str, object]:
    product_row = row
    stock_status = getattr(product_row, "stock_status")
    availability_status = getattr(product_row, "availability_status")
    stock_quantity = int(getattr(product_row, "stock_quantity") or 0)
    low_stock_threshold = int(getattr(product_row, "low_stock_threshold") or 0)

    return {
        "id": str(getattr(product_row, "product_id")),
        "name": getattr(product_row, "name"),
        "unit_label": getattr(product_row, "unit_label"),
        "seller": {
            "id": str(getattr(product_row, "seller_id")),
            "store_name": getattr(product_row, "store_name"),
        },
        "base_price": format_money(
            Decimal(getattr(product_row, "base_price")),
        ),
        "discounted_price": None,
        "is_on_sale": False,
        "is_low_stock": stock_status == ProductStockStatus.LOW_STOCK
        or (0 < stock_quantity <= low_stock_threshold),
        "image_url": None,
        "category": getattr(product_row, "category_name"),
        "description": getattr(product_row, "description"),
        "shelf_life_text": getattr(product_row, "shelf_life_text"),
        "stock_status": stock_status.value
        if hasattr(stock_status, "value")
        else str(stock_status),
        "availability_status": (
            availability_status.value
            if hasattr(availability_status, "value")
            else str(availability_status)
        ),
        "tags": [],
        "categories": [getattr(product_row, "category_name")]
        if getattr(product_row, "category_name")
        else [],
        "seller_rating": float(getattr(product_row, "seller_rating")),
        "seller_review_count": int(getattr(product_row, "seller_review_count") or 0),
    }


def location_payload(row: object) -> dict[str, object]:
    return {
        "id": str(getattr(row, "location_id")),
        "name": getattr(row, "name"),
        "address_text": getattr(row, "address_text"),
        "latitude": float(getattr(row, "latitude")),
        "longitude": float(getattr(row, "longitude")),
    }


async def get_seller_overview_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    range_value: str,
) -> SellerInsight:
    if not can_do_seller_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seller role is required to access this endpoint.",
        )

    seller_profile = await seller_profile_for_user(db, user)
    if seller_profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Seller profile not found.",
        )

    start = range_start(range_value)
    previous_start = previous_range_start(range_value, start)

    current_metrics = await db.execute(
        select(
            func.coalesce(func.sum(SellerDailyMetric.orders_count), 0).label(
                "orders_count"
            ),
            func.coalesce(func.sum(SellerDailyMetric.earnings_amount), 0).label(
                "earnings_amount"
            ),
        ).where(
            SellerDailyMetric.seller_id == seller_profile.id,
            SellerDailyMetric.metric_date >= start.date(),
        )
    )
    previous_metrics = await db.execute(
        select(
            func.coalesce(func.sum(SellerDailyMetric.orders_count), 0).label(
                "orders_count"
            ),
            func.coalesce(func.sum(SellerDailyMetric.earnings_amount), 0).label(
                "earnings_amount"
            ),
        ).where(
            SellerDailyMetric.seller_id == seller_profile.id,
            SellerDailyMetric.metric_date >= previous_start.date(),
            SellerDailyMetric.metric_date < start.date(),
        )
    )

    current_metrics_row = current_metrics.one()
    previous_metrics_row = previous_metrics.one()

    current_orders = Decimal(str(current_metrics_row.orders_count or 0))
    previous_orders = Decimal(str(previous_metrics_row.orders_count or 0))
    current_earnings = Decimal(str(current_metrics_row.earnings_amount or 0))
    previous_earnings = Decimal(str(previous_metrics_row.earnings_amount or 0))

    hustles_result = await db.execute(
        select(func.count())
        .select_from(Order)
        .where(
            Order.seller_id == seller_profile.id,
            Order.source_type == OrderSourceType.HUSTLE_LIST,
            Order.created_at >= start,
        )
    )
    previous_hustles_result = await db.execute(
        select(func.count())
        .select_from(Order)
        .where(
            Order.seller_id == seller_profile.id,
            Order.source_type == OrderSourceType.HUSTLE_LIST,
            Order.created_at >= previous_start,
            Order.created_at < start,
        )
    )

    total_hustles = int(hustles_result.scalar_one())
    previous_hustles = int(previous_hustles_result.scalar_one())

    return SellerInsight(
        range=range_value,
        total_earnings=format_money(current_earnings),
        earnings_change_pct=percentage_change(current_earnings, previous_earnings),
        total_orders=int(current_orders),
        orders_change_pct=percentage_change(current_orders, previous_orders),
        total_hustles=total_hustles,
        hustles_change_pct=percentage_change(
            Decimal(total_hustles), Decimal(previous_hustles)
        ),
        avg_rating=format_rating(Decimal(seller_profile.avg_rating)),
        avg_delivery_minutes=seller_profile.average_delivery_minutes,
        success_rate=format_success_rate(Decimal(seller_profile.success_rate)),
    )


async def get_seller_top_listings_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    range_value: str,
    limit: int,
) -> list[TopListing]:
    if not can_do_seller_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seller role is required to access this endpoint.",
        )

    seller_profile = await seller_profile_for_user(db, user)
    if seller_profile is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Seller profile not found.",
        )

    start = range_start(range_value)

    gross_sales_sum = func.coalesce(
        func.sum(ProductDailyMetric.gross_sales_amount), 0
    ).label("gross_sales_amount")
    views_sum = func.coalesce(func.sum(ProductDailyMetric.views_count), 0).label(
        "views_count"
    )
    orders_sum = func.coalesce(func.sum(ProductDailyMetric.orders_count), 0).label(
        "orders_count"
    )

    result = await db.execute(
        select(
            Product.id.label("product_id"),
            Product.name.label("name"),
            Product.unit_label.label("unit_label"),
            Product.base_price.label("base_price"),
            Product.stock_quantity.label("stock_quantity"),
            Product.low_stock_threshold.label("low_stock_threshold"),
            Product.stock_status.label("stock_status"),
            Product.availability_status.label("availability_status"),
            Product.description.label("description"),
            Product.shelf_life_text.label("shelf_life_text"),
            Product.seller_id.label("seller_id"),
            SellerProfile.store_name.label("store_name"),
            func.min(Category.name).label("category_name"),
            SellerProfile.avg_rating.label("seller_rating"),
            SellerProfile.rating_count.label("seller_review_count"),
            gross_sales_sum,
            views_sum,
            orders_sum,
        )
        .select_from(ProductDailyMetric)
        .join(Product, ProductDailyMetric.product_id == Product.id)
        .join(SellerProfile, Product.seller_id == SellerProfile.id)
        .outerjoin(product_categories, Product.id == product_categories.c.product_id)
        .outerjoin(Category, product_categories.c.category_id == Category.id)
        .where(
            Product.seller_id == seller_profile.id,
            ProductDailyMetric.metric_date >= start.date(),
        )
        .group_by(
            Product.id,
            Product.name,
            Product.unit_label,
            Product.base_price,
            Product.stock_quantity,
            Product.low_stock_threshold,
            Product.stock_status,
            Product.availability_status,
            Product.description,
            Product.shelf_life_text,
            Product.seller_id,
            SellerProfile.store_name,
            SellerProfile.avg_rating,
            SellerProfile.rating_count,
        )
        .order_by(gross_sales_sum.desc())
        .limit(limit)
    )

    rows = result.all()
    payload: list[TopListing] = []
    for row in rows:
        payload.append(
            TopListing(
                product=product_payload(row),
                gross_sales_amount=format_money(Decimal(row.gross_sales_amount or 0)),
                views_count=int(row.views_count or 0),
                orders_count=int(row.orders_count or 0),
            )
        )

    return payload


async def get_seller_hot_zones_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    range_value: str,
    limit: int,
) -> list[HotZone]:
    if not can_do_seller_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seller role is required to access this endpoint.",
        )

    _ = user
    start = range_start(range_value)
    previous_start = previous_range_start(range_value, start)

    current_orders_sum = func.coalesce(
        func.sum(LocationDailyMetric.orders_count), 0
    ).label("orders_count")

    current_result = await db.execute(
        select(
            LocationDailyMetric.location_id.label("location_id"),
            ServiceAreaLocation.name.label("name"),
            ServiceAreaLocation.address_text.label("address_text"),
            ServiceAreaLocation.latitude.label("latitude"),
            ServiceAreaLocation.longitude.label("longitude"),
            current_orders_sum,
        )
        .select_from(LocationDailyMetric)
        .join(
            ServiceAreaLocation,
            LocationDailyMetric.location_id == ServiceAreaLocation.id,
        )
        .where(LocationDailyMetric.metric_date >= start.date())
        .group_by(
            LocationDailyMetric.location_id,
            ServiceAreaLocation.name,
            ServiceAreaLocation.address_text,
            ServiceAreaLocation.latitude,
            ServiceAreaLocation.longitude,
        )
        .order_by(current_orders_sum.desc())
        .limit(limit)
    )

    previous_result = await db.execute(
        select(
            LocationDailyMetric.location_id.label("location_id"),
            func.coalesce(func.sum(LocationDailyMetric.orders_count), 0).label(
                "orders_count"
            ),
        )
        .select_from(LocationDailyMetric)
        .where(
            LocationDailyMetric.metric_date >= previous_start.date(),
            LocationDailyMetric.metric_date < start.date(),
        )
        .group_by(LocationDailyMetric.location_id)
    )

    previous_rows = {
        row.location_id: int(row.orders_count or 0) for row in previous_result.all()
    }

    payload: list[HotZone] = []
    for row in current_result.all():
        current_orders = int(row.orders_count or 0)
        previous_orders = Decimal(previous_rows.get(row.location_id, 0))
        payload.append(
            HotZone(
                location=location_payload(row),
                orders_count=current_orders,
                change_pct=percentage_change(Decimal(current_orders), previous_orders),
            )
        )

    return payload


async def get_service_area_opportunities_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    limit: int,
) -> list[ServiceAreaOpportunity]:
    if not can_do_seller_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seller role is required to access this endpoint.",
        )

    result = await db.execute(
        select(
            LocationDailyMetric.location_id.label("location_id"),
            ServiceAreaLocation.name.label("name"),
            ServiceAreaLocation.address_text.label("address_text"),
            ServiceAreaLocation.latitude.label("latitude"),
            ServiceAreaLocation.longitude.label("longitude"),
            LocationDailyMetric.orders_count.label("orders_count"),
            LocationDailyMetric.buyers_count.label("buyers_count"),
            LocationDailyMetric.avg_order_amount.label("avg_order_amount"),
        )
        .select_from(LocationDailyMetric)
        .join(
            ServiceAreaLocation,
            LocationDailyMetric.location_id == ServiceAreaLocation.id,
        )
        .order_by(LocationDailyMetric.metric_date.desc())
        .limit(limit * 3)
    )

    payload: list[ServiceAreaOpportunity] = []
    seen_locations: set[str] = set()
    for row in result.all():
        location_id = str(row.location_id)
        if location_id in seen_locations:
            continue
        seen_locations.add(location_id)
        payload.append(
            ServiceAreaOpportunity(
                location=location_payload(row),
                weekly_orders=int(row.orders_count or 0),
                customers_count=int(row.buyers_count or 0),
                avg_order_amount=format_money(Decimal(row.avg_order_amount or 0)),
            )
        )
        if len(payload) >= limit:
            break

    return payload


async def get_buyer_spending_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    range_value: str,
) -> BuyerSpending:
    if not can_do_buyer_actions(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Buyer role is required to access this endpoint.",
        )

    start = (
        range_start(range_value) if range_value in {"today", "week", "month"} else None
    )

    total_amount = (
        Order.subtotal_amount + Order.delivery_fee_amount + Order.service_fee_amount
    )
    stmt = select(
        func.coalesce(func.sum(total_amount), 0).label("total_spent"),
        func.count().label("total_orders"),
    ).where(Order.buyer_id == user.id, Order.status == OrderStatus.DONE)
    if start is not None:
        stmt = stmt.where(Order.created_at >= start)

    row = (await db.execute(stmt)).one()
    total_spent = Decimal(str(row.total_spent or 0))
    total_orders = int(row.total_orders or 0)
    average_order_price = (
        total_spent / total_orders if total_orders else Decimal("0.00")
    )

    return BuyerSpending(
        total_spent=format_money(total_spent),
        total_orders=total_orders,
        average_order_price=format_money(average_order_price),
    )


async def create_view_event_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: ViewEventCreate,
) -> ViewEventResponse:
    if request.entity_type == EntityType.PRODUCT:
        result = await db.execute(
            select(Product.id).where(Product.id == request.entity_id)
        )
        if result.scalar_one_or_none() is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found.",
            )
        event = ListingViewEvent(
            viewer_user_id=user.id,
            product_id=request.entity_id,
            source_screen=request.source_screen,
        )
    else:
        result = await db.execute(
            select(SellerProfile.id).where(SellerProfile.id == request.entity_id)
        )
        if result.scalar_one_or_none() is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Seller profile not found.",
            )
        event = ListingViewEvent(
            viewer_user_id=user.id,
            seller_id=request.entity_id,
            source_screen=request.source_screen,
        )

    db.add(event)
    return ViewEventResponse(accepted=True)
