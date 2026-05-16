from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from decimal import ROUND_HALF_UP, Decimal

import httpx
from fastapi import status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.carts.schema import CartResponse
from src.api.v1.carts.utils import serialize_cart_async as serialize_cart
from src.api.v1.orders import utils as order_utils
from src.api.v1.orders.queries import (
    get_order_or_404,
    seller_profile_for_user,
    get_current_cart_or_none,
    resolve_address,
    get_order_item_by_id,
    get_product_by_id,
)
from src.api.v1.orders.schema import (
    AdjustmentDecisionRequest,
    AlternativeDecisionRequest,
    BuyerOrdersSummaryResponse,
    CheckoutPaymentResponse,
    CheckoutPreviewRequest,
    CheckoutPreviewResponse,
    CheckoutRequest,
    CheckoutResponse,
    CheckoutSource,
    OrderAdjustmentRequest,
    OrderComplaintCreateRequest,
    OrderComplaintResponse,
    OrderComplaintResultResponse,
    OrderDecision,
    OrderDetailResponse,
    OrderItemAlternativeRequest,
    OrderItemCancelRequest,
    OrderPageResponse,
    OrderReviewCreateRequest,
    OrderReviewResponse,
    OrderReviewResultResponse,
    OrderStatusResponse,
    PaymentMethod,
)
from src.api.v1.payments.utils import PaystackClient
from src.core.exceptions import HTTPException
from src.models.auth import Address
from src.models.carts import Cart, CartItem, CartStatus
from src.models.catalog import Product
from src.models.marketplace import (
    HustleList,
    HustleListDispatchStatus,
    HustleListStatus,
    ServiceAreaLocation,
    ServiceAreaLocationProvider,
)
from src.models.orders import (
    ComplaintTag,
    Order,
    OrderComplaint,
    OrderComplaintTag,
    OrderItem,
    OrderItemAdjustment,
    OrderItemAdjustmentStatus,
    OrderItemAlternative,
    OrderItemAlternativeStatus,
    OrderItemFulfillmentStatus,
    OrderReview,
    OrderReviewTag,
    OrderSourceType,
    OrderStatus,
    OrderStatusEvent,
    ReviewTag,
)
from src.models.payments import (
    Payment,
    SavedPaymentMethod,
    Wallet,
    WalletTransaction,
    WalletTransactionStatus,
    WalletTransactionType,
)
from src.models.payments import (
    PaymentStatus as PaymentRecordStatus,
)
from src.models.payments import PaymentStatus as PaymentStatusResponse
from src.models.sellers import SellerProfile
from src.api.v1.shared.utils.currency import format_money


def next_order_number() -> str:
    """Generate next order number."""
    return order_utils.next_order_number()


async def initialize_paystack_checkout(
    *,
    email: str,
    amount: Decimal,
    reference: str,
    metadata: dict[str, str],
) -> tuple[str, str]:
    client = PaystackClient()
    try:
        response = await client.initialize_transaction(
            email=email,
            amount=int((amount * Decimal("100")).quantize(Decimal("1"))),
            reference=reference,
            metadata=metadata,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Unable to initialize Paystack checkout.",
        ) from exc
    finally:
        await client.close()

    if response.get("status") is not True:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(
                response.get("message") or "Unable to initialize Paystack checkout."
            ),
        )

    data = response.get("data", {})
    provider_reference = str(data.get("reference") or reference)
    authorization_url = str(data.get("authorization_url") or "")
    return provider_reference, authorization_url


async def sync_review_tags(
    db: AsyncSession, review: OrderReview, tags: list[str]
) -> None:
    normalized = [tag.strip() for tag in tags if tag.strip()]
    desired_lower = {tag.lower() for tag in normalized}

    existing_result = await db.execute(
        select(OrderReviewTag)
        .options(selectinload(OrderReviewTag.review_tag))
        .where(OrderReviewTag.order_review_id == review.id)
    )
    existing_rows = list(existing_result.scalars().all())

    for row in existing_rows:
        if row.review_tag.name.lower() not in desired_lower:
            await db.delete(row)

    existing_lower = {row.review_tag.name.lower() for row in existing_rows}
    for tag_name in normalized:
        if tag_name.lower() in existing_lower:
            continue
        tag_result = await db.execute(
            select(ReviewTag).where(ReviewTag.name == tag_name).limit(1)
        )
        tag = tag_result.scalar_one_or_none()
        if tag is None:
            tag = ReviewTag(name=tag_name)
            db.add(tag)
            await db.flush()
        db.add(OrderReviewTag(order_review_id=review.id, review_tag_id=tag.id))


async def sync_complaint_tags(
    db: AsyncSession,
    complaint: OrderComplaint,
    tags: list[str],
) -> None:
    normalized = [tag.strip() for tag in tags if tag.strip()]
    desired_lower = {tag.lower() for tag in normalized}

    existing_result = await db.execute(
        select(OrderComplaintTag)
        .options(selectinload(OrderComplaintTag.complaint_tag))
        .where(OrderComplaintTag.order_complaint_id == complaint.id)
    )
    existing_rows = list(existing_result.scalars().all())

    for row in existing_rows:
        if row.complaint_tag.name.lower() not in desired_lower:
            await db.delete(row)

    existing_lower = {row.complaint_tag.name.lower() for row in existing_rows}
    for tag_name in normalized:
        if tag_name.lower() in existing_lower:
            continue
        tag_result = await db.execute(
            select(ComplaintTag).where(ComplaintTag.name == tag_name).limit(1)
        )
        tag = tag_result.scalar_one_or_none()
        if tag is None:
            tag = ComplaintTag(name=tag_name)
            db.add(tag)
            await db.flush()
        db.add(
            OrderComplaintTag(order_complaint_id=complaint.id, complaint_tag_id=tag.id)
        )


async def preview_checkout_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: CheckoutPreviewRequest | None = None,
) -> CheckoutPreviewResponse:
    cart = await get_current_cart_or_none(db, user.id)
    if cart is None:
        return CheckoutPreviewResponse(
            cart=None, order_groups=[], wallet_balance="0.00"
        )

    cart_response = await serialize_cart(db, cart.id)
    order_groups = await order_utils.serialize_cart_groups(cart)
    wallet = await order_utils.wallet_summary(db, user.id)

    return CheckoutPreviewResponse(
        cart=cart_response,
        order_groups=order_groups,
        wallet_balance=wallet.available_balance,
    )


async def checkout_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: CheckoutRequest,
) -> CheckoutResponse:
    source_cart: Cart | None = None
    source_hustle_list: HustleList | None = None
    seller: SellerProfile | None = None
    selected_delivery_address: Address | None = None
    items_data: list[dict[str, object]] = []
    subtotal = Decimal("0.00")

    if request.source in {CheckoutSource.CURRENT_CART, CheckoutSource.CART_ID}:
        cart_filters = [Cart.buyer_id == user.id]
        if request.source == CheckoutSource.CURRENT_CART:
            cart_filters.append(Cart.status == CartStatus.ACTIVE)
        else:
            cart_filters.append(Cart.id == request.cart_id)

        cart_result = await db.execute(
            select(Cart)
            .options(
                selectinload(Cart.items)
                .selectinload(CartItem.product)
                .selectinload(Product.seller),
            )
            .where(*cart_filters)
            .order_by(desc(Cart.updated_at), desc(Cart.id))
            .limit(1)
        )
        source_cart = cart_result.scalar_one_or_none()
        if source_cart is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Cart not found.")

        if not source_cart.items:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Cart is empty.")

        products = [
            item.product for item in source_cart.items if item.product is not None
        ]
        if len(products) != len(source_cart.items):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Cart contains items that are no longer available.",
            )

        seller_ids = {product.seller_id for product in products}
        if len(seller_ids) != 1:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Checkout currently supports one seller per order.",
            )
        seller = products[0].seller

        selected_delivery_address = await resolve_address(
            db, user.id, request.delivery_address_id
        )

        for item in source_cart.items:
            final_unit_price = (
                item.discount_price_snapshot
                if item.discount_price_snapshot is not None
                else item.unit_price_snapshot
            )
            items_data.append(
                {
                    "product_id": item.product_id,
                    "source_hustle_list_item_id": None,
                    "display_name": item.product_name_snapshot,
                    "quantity": Decimal(str(item.quantity)),
                    "unit_label": item.unit_label_snapshot,
                    "base_unit_price": item.unit_price_snapshot,
                    "final_unit_price": final_unit_price,
                    "line_total": item.line_total_snapshot,
                }
            )
            subtotal += item.line_total_snapshot

        source_type = OrderSourceType.CATALOG_CHECKOUT
        pickup_location = None
        delivery_fee = (
            request.delivery_fee
            if request.delivery_fee is not None
            else (Decimal("1000.00") if subtotal > 0 else Decimal("0.00"))
        )
    else:
        hustle_result = await db.execute(
            select(HustleList)
            .options(
                selectinload(HustleList.items),
                selectinload(HustleList.dispatches),
            )
            .where(
                HustleList.buyer_id == user.id, HustleList.id == request.hustle_list_id
            )
            .limit(1)
        )
        source_hustle_list = hustle_result.scalar_one_or_none()
        if source_hustle_list is None:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, detail="Hustle list not found."
            )

        accepted_dispatch = next(
            (
                dispatch
                for dispatch in source_hustle_list.dispatches
                if dispatch.status == HustleListDispatchStatus.ACCEPTED
                and dispatch.accepted_by_seller_id is not None
            ),
            None,
        )
        if accepted_dispatch is None:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Hustle list must be accepted by a seller before checkout.",
            )
        seller = None
        if accepted_dispatch.accepted_by_seller_id is not None:
            seller_result = await db.execute(
                select(SellerProfile)
                .where(SellerProfile.id == accepted_dispatch.accepted_by_seller_id)
                .limit(1)
            )
            seller = seller_result.scalar_one_or_none()

        if seller is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Seller not found.")

        selected_delivery_address = await resolve_address(
            db, user.id, request.delivery_address_id
        )
        if selected_delivery_address is None:
            selected_delivery_address = source_hustle_list.delivery_address

        for list_item in source_hustle_list.items:
            unit_price = list_item.target_price or Decimal("0.00")
            line_total = unit_price * list_item.quantity_value
            subtotal += line_total
            items_data.append(
                {
                    "product_id": None,
                    "source_hustle_list_item_id": list_item.id,
                    "display_name": list_item.requested_name,
                    "quantity": list_item.quantity_value,
                    "unit_label": list_item.unit_label,
                    "base_unit_price": unit_price,
                    "final_unit_price": unit_price,
                    "line_total": line_total,
                }
            )

        delivery_fee = (
            request.delivery_fee
            if request.delivery_fee is not None
            else source_hustle_list.delivery_fee
        )
        source_type = OrderSourceType.HUSTLE_LIST
        pickup_location = None
        if source_hustle_list.shopping_location is not None:
            place_id = source_hustle_list.shopping_location.provider_place_id
            pickup_result = await db.execute(
                select(ServiceAreaLocation)
                .where(
                    ServiceAreaLocation.provider_place_id == place_id,
                    ServiceAreaLocation.provider
                    == ServiceAreaLocationProvider.GOOGLE_PLACES,
                )
                .limit(1)
            )
            pickup_location = pickup_result.scalar_one_or_none()
            if pickup_location is None:
                pickup_location = ServiceAreaLocation(
                    provider=ServiceAreaLocationProvider.GOOGLE_PLACES,
                    provider_place_id=place_id,
                    name=source_hustle_list.shopping_location.name,
                    address_text=source_hustle_list.shopping_location.address_text
                    or "",
                    latitude=source_hustle_list.shopping_location.latitude or 0.0,
                    longitude=source_hustle_list.shopping_location.longitude or 0.0,
                )
                db.add(pickup_location)
                await db.flush()

    if selected_delivery_address is None:
        selected_delivery_address = await resolve_address(db, user.id, None)

    service_fee = (
        (subtotal * Decimal("0.05")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        if subtotal > 0
        else Decimal("0.00")
    )
    total = subtotal + delivery_fee + service_fee

    wallet_result = await db.execute(
        select(Wallet).where(Wallet.user_id == user.id).limit(1)
    )
    wallet = wallet_result.scalar_one_or_none()
    if wallet is None:
        wallet = Wallet(user_id=user.id)
        db.add(wallet)
        await db.flush()

    payment_method = request.payment_method
    payment_record_status = PaymentRecordStatus.PENDING
    authorization_url: str | None = None
    provider_reference = f"pay_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}"

    if payment_method == PaymentMethod.WALLET:
        if wallet.available_balance < total:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail="Insufficient wallet balance.",
            )
        wallet.available_balance = wallet.available_balance - total
        payment_record_status = PaymentRecordStatus.SUCCEEDED
    else:
        provider_reference, authorization_url = await initialize_paystack_checkout(
            email=user.email,
            amount=total,
            reference=provider_reference,
            metadata={
                "purpose": "order_checkout",
                "buyer_id": str(user.id),
                "source": request.source.value,
            },
        )

    order = Order(
        order_number=next_order_number(),
        buyer_id=user.id,
        seller_id=seller.id,
        source_type=source_type,
        source_cart_id=source_cart.id if source_cart is not None else None,
        source_hustle_list_id=source_hustle_list.id
        if source_hustle_list is not None
        else None,
        status=(
            OrderStatus.ACCEPTED
            if payment_record_status == PaymentRecordStatus.SUCCEEDED
            else OrderStatus.PENDING_PAYMENT
        ),
        pickup_location_id=pickup_location.id if pickup_location is not None else None,
        delivery_address_snapshot_json=(
            {
                "address_text": selected_delivery_address.address_text
                or selected_delivery_address.name,
                "latitude": str(selected_delivery_address.latitude),
                "longitude": str(selected_delivery_address.longitude),
            }
            if selected_delivery_address is not None
            else {}
        ),
        subtotal_amount=subtotal,
        delivery_fee_amount=delivery_fee,
        service_fee_amount=service_fee,
        seller_eta_minutes=None,
        special_instructions=request.special_instructions or "",
    )
    db.add(order)
    await db.flush()

    for item_data in items_data:
        db.add(
            OrderItem(
                order_id=order.id,
                product_id=item_data["product_id"],
                source_hustle_list_item_id=item_data["source_hustle_list_item_id"],
                display_name=str(item_data["display_name"]),
                quantity=item_data["quantity"],
                unit_label=str(item_data["unit_label"] or ""),
                base_unit_price=item_data["base_unit_price"],
                final_unit_price=item_data["final_unit_price"],
                line_total=item_data["line_total"],
                fulfillment_status=OrderItemFulfillmentStatus.PENDING,
                note="",
                image_snapshot="",
            )
        )

    db.add(
        OrderStatusEvent(
            order_id=order.id,
            status=order.status,
            actor_user_id=user.id,
            note="",
        )
    )

    saved_payment_method = None
    if request.saved_payment_method_id is not None:
        saved_method_result = await db.execute(
            select(SavedPaymentMethod)
            .where(
                SavedPaymentMethod.id == request.saved_payment_method_id,
                SavedPaymentMethod.user_id == user.id,
            )
            .limit(1)
        )
        saved_payment_method = saved_method_result.scalar_one_or_none()

    payment_record = Payment(
        id=uuid.uuid4(),
        order_id=order.id,
        payer_user_id=user.id,
        saved_payment_method_id=saved_payment_method.id
        if saved_payment_method is not None
        else None,
        payment_method=payment_method.value,
        provider_reference=provider_reference,
        amount=total,
        currency_code="NGN",
        status=payment_record_status,
        paid_at=datetime.now(timezone.utc)
        if payment_record_status == PaymentRecordStatus.SUCCEEDED
        else None,
    )
    db.add(payment_record)

    if payment_method == PaymentMethod.WALLET:
        wallet_transaction = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type=WalletTransactionType.PAYMENT,
            amount=total,
            balance_after=wallet.available_balance,
            reference_type="order",
            reference_id=order.id,
            status=WalletTransactionStatus.SUCCEEDED,
            note="Order payment",
        )
        db.add(wallet_transaction)

    if source_cart is not None:
        source_cart.status = CartStatus.CONVERTED
        source_cart.checked_out_at = datetime.now(timezone.utc)
    if source_hustle_list is not None:
        source_hustle_list.status = HustleListStatus.CONVERTED

    order_summary_response = order_utils.order_summary(
        order=order,
        buyer=user,
        seller=seller,
        delivery_address=selected_delivery_address,
        items_count=len(items_data),
    )
    wallet_payload = await order_utils.wallet_summary(db, user.id)

    return CheckoutResponse(
        orders=[order_summary_response],
        payment=CheckoutPaymentResponse(
            id=payment_record.id,
            payment_method=payment_method,
            status=(
                PaymentStatusResponse.SUCCEEDED
                if payment_record_status == PaymentRecordStatus.SUCCEEDED
                else PaymentStatusResponse.FAILED
                if payment_record_status == PaymentRecordStatus.FAILED
                else PaymentStatusResponse.PENDING
            ),
            amount=format_money(total),
            reference=provider_reference,
            authorization_url=authorization_url,
        ),
        wallet=wallet_payload,
    )


async def list_buyer_live_orders_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> OrderPageResponse:
    return await order_utils.order_page(
        db,
        filters=[
            Order.buyer_id == user.id,
            Order.status.in_(
                [
                    OrderStatus.ACCEPTED,
                    OrderStatus.SHOPPING,
                    OrderStatus.DELIVERING,
                ]
            ),
        ],
        cursor=cursor,
        limit=limit,
    )


async def list_buyer_history_orders_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> OrderPageResponse:
    return await order_utils.order_page(
        db,
        filters=[
            Order.buyer_id == user.id,
            Order.status.in_([OrderStatus.DONE, OrderStatus.CANCELLED]),
        ],
        cursor=cursor,
        limit=limit,
    )


async def get_buyer_orders_summary_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    range_value: str,
) -> BuyerOrdersSummaryResponse:
    now = datetime.now(timezone.utc)
    start = None
    if range_value == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    elif range_value == "week":
        start = now - timedelta(days=7)
    elif range_value == "month":
        start = now - timedelta(days=30)

    filters = [Order.buyer_id == user.id, Order.status == OrderStatus.DONE]
    if start is not None:
        filters.append(Order.created_at >= start)

    count_result = await db.execute(
        select(func.count()).select_from(Order).where(*filters)
    )
    total_orders = int(count_result.scalar_one())
    sum_result = await db.execute(
        select(
            func.coalesce(
                func.sum(
                    Order.subtotal_amount
                    + Order.delivery_fee_amount
                    + Order.service_fee_amount
                ),
                Decimal("0.00"),
            )
        ).where(*filters)
    )
    total_spent = Decimal(str(sum_result.scalar_one()))
    average_order_price = (
        (total_spent / total_orders) if total_orders > 0 else Decimal("0.00")
    )
    return BuyerOrdersSummaryResponse(
        total_spent=format_money(total_spent),
        total_orders=total_orders,
        average_order_price=format_money(average_order_price),
    )


async def list_seller_active_orders_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> OrderPageResponse:
    seller_profile = await seller_profile_for_user(db, user)
    return await order_utils.order_page(
        db,
        filters=[
            Order.seller_id == seller_profile.id,
            Order.status.in_(
                [
                    OrderStatus.ACCEPTED,
                    OrderStatus.SHOPPING,
                    OrderStatus.DELIVERING,
                ]
            ),
        ],
        cursor=cursor,
        limit=limit,
    )


async def list_seller_history_orders_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    cursor: str | None,
    limit: int,
) -> OrderPageResponse:
    seller_profile = await seller_profile_for_user(db, user)
    return await order_utils.order_page(
        db,
        filters=[
            Order.seller_id == seller_profile.id,
            Order.status.in_([OrderStatus.DONE, OrderStatus.CANCELLED]),
        ],
        cursor=cursor,
        limit=limit,
    )


async def get_order_service(
    db: AsyncSession, user: AuthenticatedActor, order_id: uuid.UUID
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    order_utils.ensure_order_access(user=user, order=order)
    return await order_utils.serialize_order_detail(db, order)


async def get_order_status_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
) -> OrderStatusResponse:
    order = await get_order_or_404(db, order_id)
    order_utils.ensure_order_access(user=user, order=order)

    event_result = await db.execute(
        select(OrderStatusEvent)
        .where(OrderStatusEvent.order_id == order.id)
        .order_by(OrderStatusEvent.created_at.desc())
        .limit(1)
    )
    latest_event = event_result.scalar_one_or_none()
    updated_at = (
        latest_event.created_at if latest_event is not None else order.updated_at
    )
    return OrderStatusResponse(
        order_id=order.id,
        status=order.status.value,
        updated_at=updated_at,
    )


async def cancel_order_item_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    item_id: uuid.UUID,
    request: OrderItemCancelRequest,
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    order_utils.ensure_order_access(user=user, order=order)

    item = await get_order_item_by_id(db, order.id, item_id)
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order item not found.")
    if item.fulfillment_status == OrderItemFulfillmentStatus.CANCELLED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order item is already cancelled.",
        )

    item.fulfillment_status = OrderItemFulfillmentStatus.CANCELLED
    item.line_total = Decimal("0.00")

    subtotal_result = await db.execute(
        select(func.coalesce(func.sum(OrderItem.line_total), Decimal("0.00"))).where(
            OrderItem.order_id == order.id
        )
    )
    order.subtotal_amount = Decimal(str(subtotal_result.scalar_one()))
    db.add(item)
    db.add(order)

    return await order_utils.serialize_order_detail(db, order)


async def create_item_alternative_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    item_id: uuid.UUID,
    request: OrderItemAlternativeRequest,
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    seller_profile = await seller_profile_for_user(db, user)
    if order.seller_id != seller_profile.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the assigned seller can suggest alternatives.",
        )

    item = await get_order_item_by_id(db, order.id, item_id)
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order item not found.")

    if request.suggested_product_id is not None:
        product = await get_product_by_id(db, request.suggested_product_id)
        if product is None:
            raise HTTPException(
                status.HTTP_404_NOT_FOUND, detail="Suggested product not found."
            )

    db.add(
        OrderItemAlternative(
            order_id=order.id,
            order_item_id=item.id,
            suggested_by_user_id=user.id,
            suggested_product_id=request.suggested_product_id,
            suggested_name=request.suggested_name or "",
            suggested_unit_label=request.suggested_unit_label or "",
            suggested_price=request.suggested_price,
            note=request.note or "",
        )
    )

    return await order_utils.serialize_order_detail(db, order)


async def decide_alternative_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    alternative_id: uuid.UUID,
    request: AlternativeDecisionRequest,
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    if user.id != order.buyer_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the buyer can decide on alternatives.",
        )

    alternative_result = await db.execute(
        select(OrderItemAlternative)
        .join(OrderItem, OrderItem.id == OrderItemAlternative.order_item_id)
        .where(
            OrderItemAlternative.id == alternative_id,
            OrderItem.order_id == order.id,
        )
        .limit(1)
    )
    alternative = alternative_result.scalar_one_or_none()
    if alternative is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Alternative not found.")
    if alternative.status != OrderItemAlternativeStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Alternative has already been decided.",
        )

    item_result = await db.execute(
        select(OrderItem).where(OrderItem.id == alternative.order_item_id).limit(1)
    )
    item = item_result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order item not found.")

    if request.decision == OrderDecision.APPROVE:
        alternative.status = OrderItemAlternativeStatus.APPROVED
        item.fulfillment_status = OrderItemFulfillmentStatus.SUBSTITUTED
        if alternative.suggested_name:
            item.display_name = alternative.suggested_name
        if alternative.suggested_unit_label:
            item.unit_label = alternative.suggested_unit_label
        if alternative.suggested_price is not None:
            item.final_unit_price = alternative.suggested_price
            item.line_total = alternative.suggested_price * item.quantity
        db.add(item)
    else:
        alternative.status = OrderItemAlternativeStatus.REJECTED

    alternative.reviewed_by_user_id = user.id
    alternative.reviewed_at = datetime.now(timezone.utc)
    db.add(alternative)

    subtotal_result = await db.execute(
        select(func.coalesce(func.sum(OrderItem.line_total), Decimal("0.00"))).where(
            OrderItem.order_id == order.id
        )
    )
    order.subtotal_amount = Decimal(str(subtotal_result.scalar_one()))
    db.add(order)

    return await order_utils.serialize_order_detail(db, order)


async def create_item_adjustment_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    item_id: uuid.UUID,
    request: OrderAdjustmentRequest,
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    seller_profile = await seller_profile_for_user(db, user)
    if order.seller_id != seller_profile.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the assigned seller can propose adjustments.",
        )

    item = await get_order_item_by_id(db, order.id, item_id)
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order item not found.")

    db.add(
        OrderItemAdjustment(
            order_id=order.id,
            order_item_id=item.id,
            proposed_by_user_id=user.id,
            old_unit_price=item.final_unit_price,
            new_unit_price=request.new_unit_price,
            reason=request.reason or "",
        )
    )

    return await order_utils.serialize_order_detail(db, order)


async def decide_adjustment_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    adjustment_id: uuid.UUID,
    request: AdjustmentDecisionRequest,
) -> OrderDetailResponse:
    order = await get_order_or_404(db, order_id)
    if user.id != order.buyer_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the buyer can decide on adjustments.",
        )

    adjustment_result = await db.execute(
        select(OrderItemAdjustment)
        .join(OrderItem, OrderItem.id == OrderItemAdjustment.order_item_id)
        .where(
            OrderItemAdjustment.id == adjustment_id,
            OrderItem.order_id == order.id,
        )
        .limit(1)
    )
    adjustment = adjustment_result.scalar_one_or_none()
    if adjustment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Adjustment not found.")
    if adjustment.status != OrderItemAdjustmentStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Adjustment has already been decided.",
        )

    item_result = await db.execute(
        select(OrderItem).where(OrderItem.id == adjustment.order_item_id).limit(1)
    )
    item = item_result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Order item not found.")

    if request.decision == OrderDecision.APPROVE:
        adjustment.status = OrderItemAdjustmentStatus.APPROVED
        item.final_unit_price = adjustment.new_unit_price
        item.line_total = adjustment.new_unit_price * item.quantity
        db.add(item)
    else:
        adjustment.status = OrderItemAdjustmentStatus.REJECTED

    adjustment.reviewed_by_user_id = user.id
    adjustment.reviewed_at = datetime.now(timezone.utc)
    db.add(adjustment)

    subtotal_result = await db.execute(
        select(func.coalesce(func.sum(OrderItem.line_total), Decimal("0.00"))).where(
            OrderItem.order_id == order.id
        )
    )
    order.subtotal_amount = Decimal(str(subtotal_result.scalar_one()))
    db.add(order)

    return await order_utils.serialize_order_detail(db, order)


async def file_complaint_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    request: OrderComplaintCreateRequest,
) -> OrderComplaintResultResponse:
    order = await get_order_or_404(db, order_id)
    seller_profile = await seller_profile_for_user(db, user)
    if order.seller_id != seller_profile.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the assigned seller can submit a complaint.",
        )

    complaint_result = await db.execute(
        select(OrderComplaint).where(OrderComplaint.order_id == order.id).limit(1)
    )
    complaint = complaint_result.scalar_one_or_none()
    if complaint is None:
        complaint = OrderComplaint(
            order_id=order.id,
            seller_id=seller_profile.id,
            buyer_id=order.buyer_id,
            comment=request.comment or "",
        )
        db.add(complaint)
        await db.flush()
    else:
        complaint.comment = request.comment or ""
        db.add(complaint)

    await sync_complaint_tags(db, complaint, request.tags or [])

    detail = await order_utils.serialize_order_detail(db, order)

    complaint_tags_result = await db.execute(
        select(OrderComplaintTag)
        .options(selectinload(OrderComplaintTag.complaint_tag))
        .where(OrderComplaintTag.order_complaint_id == complaint.id)
    )
    complaint_tags = [
        row.complaint_tag.name for row in complaint_tags_result.scalars().all()
    ]

    return OrderComplaintResultResponse(
        order=detail,
        complaint=OrderComplaintResponse(
            tags=complaint_tags,
            comment=complaint.comment or "",
            created_at=complaint.created_at,
        ),
    )


async def submit_review_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
    request: OrderReviewCreateRequest,
) -> OrderReviewResultResponse:
    order = await get_order_or_404(db, order_id)
    if user.id != order.buyer_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the buyer can submit a review.",
        )
    if order.seller_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order has no seller to review.",
        )

    review_result = await db.execute(
        select(OrderReview).where(OrderReview.order_id == order.id).limit(1)
    )
    review = review_result.scalar_one_or_none()
    if review is None:
        review = OrderReview(
            order_id=order.id,
            buyer_id=user.id,
            seller_id=order.seller_id,
        )
        db.add(review)
        await db.flush()

    review.rating = request.rating
    review.comment = request.comment or ""
    review.submitted_at = datetime.now(timezone.utc)
    db.add(review)

    await sync_review_tags(db, review, request.tags or [])

    detail = await order_utils.serialize_order_detail(db, order)

    review_tags_result = await db.execute(
        select(OrderReviewTag)
        .options(selectinload(OrderReviewTag.review_tag))
        .where(OrderReviewTag.order_review_id == review.id)
    )
    review_tags = [row.review_tag.name for row in review_tags_result.scalars().all()]

    return OrderReviewResultResponse(
        order=detail,
        review=OrderReviewResponse(
            status=("submitted" if review.submitted_at is not None else "pending"),
            rating=review.rating,
            tags=review_tags,
            comment=review.comment or "",
            submitted_at=review.submitted_at,
        ),
    )


async def reorder_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    order_id: uuid.UUID,
) -> CartResponse:
    order = await get_order_or_404(db, order_id)
    if user.id != order.buyer_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the buyer can reorder this order.",
        )

    cart_result = await db.execute(
        select(Cart)
        .options(selectinload(Cart.items))
        .where(Cart.buyer_id == user.id, Cart.status == CartStatus.ACTIVE)
        .limit(1)
    )
    cart = cart_result.scalar_one_or_none()
    if cart is None:
        cart = Cart(buyer_id=user.id, status=CartStatus.ACTIVE)
        db.add(cart)
        await db.flush()

    order_items_result = await db.execute(
        select(OrderItem).where(OrderItem.order_id == order.id)
    )
    order_items = list(order_items_result.scalars().all())
    product_ids = {
        item.product_id for item in order_items if item.product_id is not None
    }

    products_map: dict[uuid.UUID, Product] = {}
    if product_ids:
        products_result = await db.execute(
            select(Product).where(Product.id.in_(product_ids))
        )
        products_map = {
            product.id: product for product in products_result.scalars().all()
        }

    existing_items: dict[uuid.UUID, CartItem] = {}
    if product_ids:
        existing_items_result = await db.execute(
            select(CartItem).where(
                CartItem.cart_id == cart.id, CartItem.product_id.in_(product_ids)
            )
        )
        existing_items = {
            item.product_id: item for item in existing_items_result.scalars().all()
        }

    for order_item in order_items:
        if order_item.product_id is None:
            continue
        product = products_map.get(order_item.product_id)
        if product is None:
            continue
        quantity = int(order_item.quantity)
        line_total = order_item.final_unit_price * Decimal(quantity)
        cart_item = existing_items.get(product.id)
        if cart_item is None:
            db.add(
                CartItem(
                    cart_id=cart.id,
                    product_id=product.id,
                    quantity=quantity,
                    unit_label_snapshot=order_item.unit_label,
                    product_name_snapshot=order_item.display_name,
                    unit_price_snapshot=order_item.base_unit_price,
                    discount_price_snapshot=(
                        order_item.final_unit_price
                        if order_item.final_unit_price != order_item.base_unit_price
                        else None
                    ),
                    line_total_snapshot=line_total,
                )
            )
            continue

        cart_item.quantity = quantity
        cart_item.unit_label_snapshot = order_item.unit_label
        cart_item.product_name_snapshot = order_item.display_name
        cart_item.unit_price_snapshot = order_item.base_unit_price
        cart_item.discount_price_snapshot = (
            order_item.final_unit_price
            if order_item.final_unit_price != order_item.base_unit_price
            else None
        )
        cart_item.line_total_snapshot = line_total
        db.add(cart_item)

    return await serialize_cart(db, cart.id)
