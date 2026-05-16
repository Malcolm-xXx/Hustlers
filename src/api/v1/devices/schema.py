from pydantic import BaseModel, Field


class DeviceRegisterRequest(BaseModel):
    push_token: str = Field(min_length=1)
    device_id: str | None = None


class DeviceRegisterResponse(BaseModel):
    device_id: str
    platform: str = "fcm"


class DevicesListResponse(BaseModel):
    devices: list[DeviceRegisterResponse] = Field(default_factory=list)
