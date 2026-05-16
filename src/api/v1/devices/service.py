from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor
from src.api.v1.devices.schema import (
    DeviceRegisterRequest,
    DeviceRegisterResponse,
    DevicesListResponse,
)
from src.models.notifications import DeviceRegistration


async def register_device_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    request: DeviceRegisterRequest,
) -> DeviceRegisterResponse:
    if request.device_id:
        await db.execute(
            update(DeviceRegistration)
            .where(DeviceRegistration.user_id == user.id)
            .where(DeviceRegistration.device_id == request.device_id)
            .values(
                push_token=request.push_token,
                is_active=True,
            )
        )
        return DeviceRegisterResponse(
            device_id=request.device_id,
            platform="fcm",
        )

    registration = DeviceRegistration(
        user_id=user.id,
        device_id=f"dev-{uuid.uuid4().hex[:16]}",
        push_token=request.push_token,
        platform="fcm",
        is_active=True,
    )
    db.add(registration)
    await db.flush()
    await db.refresh(registration)
    return DeviceRegisterResponse(
        device_id=registration.device_id,
        platform=registration.platform,
    )


async def unregister_device_service(
    db: AsyncSession,
    user: AuthenticatedActor,
    device_id: str,
) -> Any:
    await db.execute(
        update(DeviceRegistration)
        .where(DeviceRegistration.user_id == user.id)
        .where(DeviceRegistration.device_id == device_id)
        .values(is_active=False)
    )


async def list_devices_service(
    db: AsyncSession,
    user: AuthenticatedActor,
) -> DevicesListResponse:
    from sqlalchemy import select

    result = await db.execute(
        select(DeviceRegistration)
        .where(DeviceRegistration.user_id == user.id)
        .where(DeviceRegistration.is_active.is_(True))
    )
    registrations = result.scalars().all()
    return DevicesListResponse(
        devices=[
            DeviceRegisterResponse(device_id=r.device_id, platform=r.platform)
            for r in registrations
        ]
    )
