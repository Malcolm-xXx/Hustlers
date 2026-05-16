from __future__ import annotations

from pydantic import BaseModel


class AblyTokenResponse(BaseModel):
    token: str
