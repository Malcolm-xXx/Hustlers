class AppError(Exception):
    def __init__(self, message: object, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class BadRequestError(AppError):
    def __init__(self, message: str = "Bad request"):
        super().__init__(message, status_code=400)


class HTTPException(AppError):
    def __init__(
        self,
        status_code: int,
        detail: object = "HTTP error",
        headers: dict[str, str] | None = None,
    ):
        self.detail = detail
        self.headers = headers
        super().__init__(detail, status_code=status_code)
