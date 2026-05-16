from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.v1.auth.utils import AuthenticatedActor, get_current_authenticated_actor
from src.api.v1.devices.schema import (
    DeviceRegisterRequest,
    DeviceRegisterResponse,
    DevicesListResponse,
)
from src.api.v1.devices.service import (
    list_devices_service,
    register_device_service,
    unregister_device_service,
)
from src.core.database import get_db

router = APIRouter()


@router.post(
    "/register/",
    response_model=DeviceRegisterResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_device(
    request: DeviceRegisterRequest,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_current_authenticated_actor),
):
    return await register_device_service(db, current_user, request)


@router.get("/", response_model=DevicesListResponse)
async def list_devices(
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_current_authenticated_actor),
):
    return await list_devices_service(db, current_user)


@router.delete("/{device_id}/", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: AuthenticatedActor = Depends(get_current_authenticated_actor),
):
    await unregister_device_service(db, current_user, device_id)
