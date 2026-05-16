"""Geoapify API client with async HTTPX calls."""

from __future__ import annotations

import time
from typing import Any

import httpx

from src.core.config import settings


class GeoapifyClient:
    _instance: GeoapifyClient | None = None
    _http: httpx.AsyncClient | None = None
    _autocomplete_cache: dict[str, dict] = {}
    _cache_ttl: int = 300  # 5 minutes in seconds

    def __new__(cls) -> GeoapifyClient:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._http = None
        return cls._instance

    @property
    def http(self) -> httpx.AsyncClient:
        if self._http is None:
            self._http = httpx.AsyncClient(timeout=10.0)
        return self._http

    async def close(self) -> None:
        if self._http is not None:
            await self._http.aclose()
            self._http = None
        self._autocomplete_cache.clear()

    def _get_cache_key(self, params: dict) -> str:
        return ":".join(str(v) for v in params.values())

    async def autocomplete(
        self,
        input: str,
        lat: float | None = None,
        lng: float | None = None,
        radius: float | None = None,
        language_code: str | None = None,
        limit: int = 5,
        types: list[str] | None = None,
        session_token: str | None = None,
    ) -> dict[str, Any]:
        cache_params = {
            "input": input,
            "lat": lat,
            "lng": lng,
            "radius": radius,
            "lang": language_code,
            "limit": limit,
            "types": ",".join(types) if types else "",
        }
        cache_key = self._get_cache_key(cache_params)

        if cache_key in self._autocomplete_cache:
            entry = self._autocomplete_cache[cache_key]
            if time.time() - entry["timestamp"] < self._cache_ttl:
                return entry["data"]

        params: dict[str, Any] = {
            "apiKey": settings.GEOAPIFY_API_KEY,
            "text": input,
            "limit": limit,
        }
        if language_code:
            params["lang"] = language_code
        if lat is not None and lng is not None:
            params["bias"] = f"proximity:{lng},{lat}"
        if types:
            params["type"] = ",".join(types)

        response = await self.http.get(
            "https://api.geoapify.com/v1/geocode/autocomplete",
            params=params,
        )
        response.raise_for_status()
        data = response.json()

        self._autocomplete_cache[cache_key] = {
            "data": data,
            "timestamp": time.time(),
        }
        return data

    async def get_place(
        self,
        place_id: str | None = None,
        lat: float | None = None,
        lng: float | None = None,
        language_code: str | None = None,
        features: list[str] | None = None,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {"apiKey": settings.GEOAPIFY_API_KEY}
        if place_id:
            params["id"] = place_id
        elif lat is not None and lng is not None:
            params["lat"] = lat
            params["lon"] = lng
        else:
            raise ValueError("Either place_id or lat/lng must be provided")

        if language_code:
            params["lang"] = language_code
        if features:
            params["features"] = ",".join(features)

        response = await self.http.get(
            "https://api.geoapify.com/v2/place-details",
            params=params,
        )
        response.raise_for_status()
        return response.json()

    async def reverse_geocode(
        self,
        lat: float,
        lng: float,
        language: str | None = None,
        result_type: list[str] | None = None,
        limit: int = 1,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {
            "apiKey": settings.GEOAPIFY_API_KEY,
            "lat": lat,
            "lon": lng,
            "limit": limit,
        }
        if language:
            params["lang"] = language
        if result_type:
            params["type"] = ",".join(result_type)

        response = await self.http.get(
            "https://api.geoapify.com/v1/geocode/reverse",
            params=params,
        )
        response.raise_for_status()
        return response.json()

    async def forward_geocode(
        self,
        text: str,
        lat: float | None = None,
        lng: float | None = None,
        language: str | None = None,
        limit: int = 5,
        result_type: list[str] | None = None,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {
            "apiKey": settings.GEOAPIFY_API_KEY,
            "text": text,
            "limit": limit,
        }
        if language:
            params["lang"] = language
        if lat is not None and lng is not None:
            params["bias"] = f"proximity:{lng},{lat}"
        if result_type:
            params["type"] = ",".join(result_type)

        response = await self.http.get(
            "https://api.geoapify.com/v1/geocode/search",
            params=params,
        )
        response.raise_for_status()
        return response.json()

    async def places_search(
        self,
        categories: list[str],
        filter: str | None = None,
        bias: str | None = None,
        limit: int = 20,
        lang: str | None = None,
        name: str | None = None,
        conditions: list[str] | None = None,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {
            "apiKey": settings.GEOAPIFY_API_KEY,
            "categories": ",".join(categories),
            "limit": limit,
        }
        if filter:
            params["filter"] = filter
        if bias:
            params["bias"] = bias
        if lang:
            params["lang"] = lang
        if name:
            params["name"] = name
        if conditions:
            params["conditions"] = ",".join(conditions)

        response = await self.http.get(
            "https://api.geoapify.com/v2/places",
            params=params,
        )
        response.raise_for_status()
        return response.json()
