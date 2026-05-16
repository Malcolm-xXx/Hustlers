from fastapi import APIRouter

from .ably.router import router as ably_router
from .analytics.router import router as analytics_router
from .auth.router import router as auth_router
from .carts.router import router as carts_router
from .catalog.router import router as catalog_router
from .devices.router import router as devices_router
from .discovery.router import router as discovery_router
from .locations.router import router as locations_router
from .marketplace.router import router as marketplace_router
from .messaging.router import router as messaging_router
from .notifications.router import router as notifications_router
from .onboarding.router import router as onboarding_router
from .orders.router import router as orders_router
from .payments.router import router as payments_router
from .sellers.router import router as sellers_router
from .trust.router import router as trust_router

router = APIRouter()

router.include_router(ably_router, prefix="/ably", tags=["ably"])
router.include_router(analytics_router, prefix="/analytics", tags=["analytics"])
router.include_router(auth_router, prefix="/auth", tags=["auth"])
router.include_router(carts_router, prefix="/carts", tags=["carts"])
router.include_router(catalog_router, prefix="/catalog", tags=["catalog"])
router.include_router(devices_router, prefix="/devices", tags=["devices"])
router.include_router(discovery_router, prefix="/discovery", tags=["discovery"])
router.include_router(locations_router, prefix="/locations", tags=["locations"])
router.include_router(marketplace_router, prefix="/marketplace", tags=["marketplace"])
router.include_router(messaging_router, prefix="/messaging", tags=["messaging"])
router.include_router(
    notifications_router, prefix="/notifications", tags=["notifications"]
)
router.include_router(onboarding_router, prefix="/onboarding", tags=["onboarding"])
router.include_router(orders_router, prefix="/orders", tags=["orders"])
router.include_router(payments_router, prefix="/payments", tags=["payments"])
router.include_router(sellers_router, prefix="/sellers", tags=["sellers"])
router.include_router(trust_router, prefix="/trust", tags=["trust"])
