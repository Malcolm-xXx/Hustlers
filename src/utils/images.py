import asyncio
import time
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass
from functools import lru_cache
from typing import Any

import cloudinary
import cloudinary.api
import cloudinary.uploader
from cloudinary import CloudinaryImage, CloudinaryVideo
from cloudinary.utils import api_sign_request

from src.core.config import settings
from src.core.logging import get_logger

logger = get_logger(__name__)


@dataclass
class ImageUploadResult:
    """Result from an image upload operation."""

    public_id: str
    url: str
    secure_url: str
    format: str
    width: int | None
    height: int | None
    resource_type: str
    bytes: int
    created_at: str


@dataclass
class ImageTransformation:
    """Cloudinary transformation options."""

    width: int | None = None
    height: int | None = None
    crop: str | None = None
    gravity: str | None = None
    quality: int | str | None = None
    format: str | None = None
    effect: str | None = None
    radius: int | str | None = None
    background: str | None = None
    overlay: str | None = None
    underlay: str | None = None
    color: str | None = None
    opacity: int | None = None
    angle: int | None = None
    blur: int | None = None
    brightness: int | None = None
    contrast: int | None = None
    saturation: int | None = None
    hue: int | None = None
    sepia: int | None = None
    grayscale: bool | None = None
    negative: bool | None = None
    pixelate: int | None = None
    noise: int | None = None
    vignette: bool | None = None

    def to_dict(self) -> dict[str, Any]:
        """Convert to Cloudinary transformation params dict."""
        return {key: value for key, value in self.__dict__.items() if value is not None}


@dataclass
class PresignedUploadResponse:
    """Response containing presigned upload credentials."""

    upload_url: str
    public_id: str
    signature: str
    api_key: str
    timestamp: int
    expires_in: int
    allowed_types: list[str]


ALLOWED_FILE_TYPES: dict[str, list[str]] = {
    "product_image": ["jpg", "jpeg", "png", "webp"],
    "profile_photo": ["jpg", "jpeg", "png", "webp"],
    "id_document": ["jpg", "jpeg", "png", "pdf"],
    "face_capture": ["jpg", "jpeg", "png"],
}


class BaseImageProvider(ABC):
    """Abstract base class for image storage providers."""

    @abstractmethod
    async def upload(
        self,
        file: bytes | str,
        folder: str | None = None,
        public_id: str | None = None,
        resource_type: str = "image",
        overwrite: bool = False,
        **options: Any,
    ) -> ImageUploadResult: ...

    @abstractmethod
    async def delete(self, public_id: str, resource_type: str = "image") -> dict: ...

    @abstractmethod
    def get_url(
        self,
        public_id: str,
        transformation: ImageTransformation | None = None,
        resource_type: str = "image",
    ) -> str: ...

    @abstractmethod
    async def generate_presigned_url(
        self,
        folder: str,
        file_type: str,
        resource_type: str = "image",
        expiration_minutes: int = 15,
    ) -> PresignedUploadResponse: ...

    @abstractmethod
    def validate_file_type(self, file_type: str, allowed_types: list[str]) -> bool: ...


class CloudinaryProvider(BaseImageProvider):
    """Cloudinary image provider implementation."""

    async def upload(
        self,
        file: bytes | str,
        folder: str | None = None,
        public_id: str | None = None,
        resource_type: str = "image",
        overwrite: bool = False,
        **options: Any,
    ) -> ImageUploadResult:
        upload_options: dict[str, Any] = {
            "resource_type": resource_type,
            "overwrite": overwrite,
            "use_filename": True,
            "unique_filename": not bool(public_id),
        }
        if folder:
            upload_options["folder"] = folder
        if public_id:
            upload_options["public_id"] = public_id
        upload_options.update(options)

        if settings.DEBUG:
            return self.debug_upload(file, folder, public_id, upload_options)

        result = await asyncio.to_thread(
            cloudinary.uploader.upload, file, **upload_options
        )
        return ImageUploadResult(
            public_id=result["public_id"],
            url=result["url"],
            secure_url=result["secure_url"],
            format=result["format"],
            width=result.get("width"),
            height=result.get("height"),
            resource_type=result["resource_type"],
            bytes=result.get("bytes", 0),
            created_at=result.get("created_at", ""),
        )

    def debug_upload(
        self,
        file: bytes | str,
        folder: str | None,
        public_id: str | None,
        upload_options: dict[str, Any],
    ) -> ImageUploadResult:
        file_info = (
            f"bytes ({len(file)} bytes)"
            if isinstance(file, bytes)
            else f"file (type: {type(file).__name__})"
        )
        logger.info(
            "DEBUG IMAGE UPLOAD - Would upload",
            file_info=file_info,
            folder=folder,
            public_id=public_id,
            upload_options=upload_options,
        )
        return ImageUploadResult(
            public_id=f"debug_{public_id or 'mock_id'}",
            url=f"https://debug.cloudinary.com/debug/debug_{public_id or 'mock_id'}",
            secure_url=f"https://debug.cloudinary.com/debug/debug_{public_id or 'mock_id'}",
            format="jpg",
            width=None,
            height=None,
            resource_type="image",
            bytes=0,
            created_at="",
        )

    async def delete(self, public_id: str, resource_type: str = "image") -> dict:
        return await asyncio.to_thread(
            cloudinary.uploader.destroy, public_id, resource_type=resource_type
        )

    def get_url(
        self,
        public_id: str,
        transformation: ImageTransformation | None = None,
        resource_type: str = "image",
    ) -> str:
        image = (
            CloudinaryVideo(public_id)
            if resource_type == "video"
            else CloudinaryImage(public_id)
        )
        if transformation:
            return image.build_url(transformation=transformation.to_dict())
        return image.build_url()

    async def get_info(self, public_id: str, resource_type: str = "image") -> dict:
        return await asyncio.to_thread(
            cloudinary.api.resource, public_id, resource_type=resource_type
        )

    async def generate_presigned_url(
        self,
        folder: str,
        file_type: str,
        resource_type: str = "image",
        expiration_minutes: int = 15,
    ) -> PresignedUploadResponse:
        timestamp = int(time.time())
        public_id = f"{folder}/{uuid.uuid4().hex}"

        params_to_sign = {
            "public_id": public_id,
            "timestamp": timestamp,
        }

        signature = await asyncio.to_thread(
            api_sign_request,
            params_to_sign,
            settings.CLOUDINARY_API_SECRET,
        )

        upload_url = (
            f"https://api.cloudinary.com/v1_1"
            f"/{settings.CLOUDINARY_CLOUD_NAME}/{resource_type}/upload"
        )

        return PresignedUploadResponse(
            upload_url=upload_url,
            public_id=public_id,
            signature=signature,
            api_key=settings.CLOUDINARY_API_KEY,
            timestamp=timestamp,
            expires_in=expiration_minutes * 60,
            allowed_types=ALLOWED_FILE_TYPES.get(file_type, []),
        )

    def validate_file_type(self, file_type: str, allowed_types: list[str]) -> bool:
        if not file_type:
            return False
        ext = file_type.lower().lstrip(".")
        return ext in [t.lower() for t in allowed_types]


def setup_image_provider() -> None:
    """
    Initialize the configured image provider.

    This should be called once at application startup.
    """

    match settings.IMAGE_PROVIDER:
        case "cloudinary":
            cloudinary.config(
                cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                api_key=settings.CLOUDINARY_API_KEY,
                api_secret=settings.CLOUDINARY_API_SECRET,
                secure=True,
            )
            logger.info("Cloudinary image provider initialized")

        case _:
            logger.warning(
                "Unknown IMAGE_PROVIDER=%s, defaulting to Cloudinary",
                settings.IMAGE_PROVIDER,
            )


@lru_cache(maxsize=1)
def get_image_provider() -> BaseImageProvider:
    """Factory function returning a cached image provider instance."""
    match settings.IMAGE_PROVIDER:
        case "cloudinary":
            return CloudinaryProvider()
        case _:
            logger.warning(
                "Unknown IMAGE_PROVIDER %s, defaulting to CloudinaryProvider",
                settings.IMAGE_PROVIDER,
            )
            return CloudinaryProvider()


def get_allowed_file_types(resource_type: str) -> list[str]:
    """Get allowed file types for a resource type."""
    return ALLOWED_FILE_TYPES.get(resource_type, [])
