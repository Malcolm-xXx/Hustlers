from src.core.exceptions import BadRequestError


class GoogleAuthError(BadRequestError):
    def __init__(self, message: str = "Google authentication failed."):
        super().__init__(message)
