import 'api_exceptions.dart';

enum AppErrorCategory {
  unauthorized,
  network,
  serverError,
  validation,
  notFound,
  conflict,
  rateLimited,
  forbidden,
  timeout,
  unknown,
}

class AppErrorHandler {
  AppErrorHandler._();

  static AppErrorCategory classify(ApiException e) {
    return switch (e) {
      UnauthorizedException() => AppErrorCategory.unauthorized,
      NetworkException() => AppErrorCategory.network,
      InternalServerException() ||
      BadGatewayException() ||
      ServiceUnavailableException() ||
      GatewayTimeoutException() =>
        AppErrorCategory.serverError,
      UnprocessableEntityException() || BadRequestException() => AppErrorCategory.validation,
      NotFoundException() => AppErrorCategory.notFound,
      ConflictException() => AppErrorCategory.conflict,
      TooManyRequestsException() => AppErrorCategory.rateLimited,
      ForbiddenException() => AppErrorCategory.forbidden,
      RequestTimeoutException() => AppErrorCategory.timeout,
      _ => AppErrorCategory.unknown,
    };
  }

  /// Returns a message safe to display directly in the UI.
  static String getUserMessage(ApiException e) {
    return switch (e) {
      UnauthorizedException() => 'Your session has expired. Please log in again.',
      NetworkException() => 'No internet connection. Please check your network.',
      InternalServerException() ||
      BadGatewayException() ||
      ServiceUnavailableException() ||
      GatewayTimeoutException() =>
        'Our servers are having issues. Please try again later.',
      // 400 / 422 — the server message is already user-friendly
      UnprocessableEntityException() || BadRequestException() => e.message,
      NotFoundException() => 'The requested item could not be found.',
      // 409 — server message is descriptive (e.g. "email already exists")
      ConflictException() => e.message,
      TooManyRequestsException() => 'Too many attempts. Please wait a moment and try again.',
      ForbiddenException() => "You don't have permission to perform this action.",
      RequestTimeoutException() => 'Request timed out. Please check your connection and try again.',
      RequestCancelledException() => 'Request was cancelled.',
      ResponseParseException() => 'We received an unexpected response. Please try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  static bool isUnauthorized(ApiException e) => e is UnauthorizedException;
  static bool isNetworkError(ApiException e) => e is NetworkException;
  static bool isServerError(ApiException e) =>
      e is InternalServerException ||
      e is BadGatewayException ||
      e is ServiceUnavailableException ||
      e is GatewayTimeoutException;
  static bool isValidationError(ApiException e) =>
      e is UnprocessableEntityException || e is BadRequestException;
}
