sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class BadRequestException extends ApiException {
  const BadRequestException({
    super.message = 'Bad request. Please check your input.',
    super.statusCode = 400,
    super.data,
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Unauthorized. Please log in again.',
    super.statusCode = 401,
    super.data,
  });
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Forbidden. You do not have permission.',
    super.statusCode = 403,
    super.data,
  });
}

class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.statusCode = 404,
    super.data,
  });
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({
    super.message = 'Request timed out. Please try again.',
    super.statusCode = 408,
    super.data,
  });
}

class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'Conflict. The resource already exists.',
    super.statusCode = 409,
    super.data,
  });
}

class UnprocessableEntityException extends ApiException {
  const UnprocessableEntityException({
    super.message = 'Validation failed. Please check your input.',
    super.statusCode = 422,
    super.data,
  });
}

class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({
    super.message = 'Too many requests. Please slow down.',
    super.statusCode = 429,
    super.data,
  });
}

class InternalServerException extends ApiException {
  const InternalServerException({
    super.message = 'Internal server error. Please try again later.',
    super.statusCode = 500,
    super.data,
  });
}

class BadGatewayException extends ApiException {
  const BadGatewayException({
    super.message = 'Bad gateway. Please try again later.',
    super.statusCode = 502,
    super.data,
  });
}

class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException({
    super.message = 'Service unavailable. Please try again later.',
    super.statusCode = 503,
    super.data,
  });
}

class GatewayTimeoutException extends ApiException {
  const GatewayTimeoutException({
    super.message = 'Gateway timeout. Please try again later.',
    super.statusCode = 504,
    super.data,
  });
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
    super.data,
  });
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException({
    super.message = 'Request was cancelled.',
    super.statusCode,
    super.data,
  });
}

class UnknownApiException extends ApiException {
  const UnknownApiException({
    super.message = 'Something went wrong. Please try again.',
    super.statusCode,
    super.data,
  });
}

class ResponseParseException extends ApiException {
  const ResponseParseException({
    super.message = 'Received an unexpected response from the server.',
    super.statusCode,
    super.data,
  });
}
