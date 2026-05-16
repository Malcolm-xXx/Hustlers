import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exceptions.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static ApiException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return UnknownApiException(
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  static ApiException handleParseError(Object error) {
    return const ResponseParseException();
  }

  static ApiException _handleResponseError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? serverMessage;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      final err = data['error'];
      final detail = data['detail'];
      
      if (msg is String) {
        serverMessage = msg;
      } else if (err is String) {
        serverMessage = err;
      } else if (err is Map<String, dynamic> && err['message'] is String) {
        serverMessage = err['message'] as String;
      } else if (detail is String) {
        serverMessage = detail;
      } else if (detail is List && detail.isNotEmpty && detail[0] is Map && detail[0]['msg'] is String) {
        // Handle FastAPI validation list
        serverMessage = detail[0]['msg'] as String;
      }
    }

    return switch (statusCode) {
      400 => BadRequestException(
          message: serverMessage ?? 'Bad request. Please check your input.',
          data: data,
        ),
      401 => UnauthorizedException(
          message: serverMessage ?? 'Unauthorized. Please log in again.',
          data: data,
        ),
      403 => ForbiddenException(
          message: serverMessage ?? 'Forbidden. You do not have permission.',
          data: data,
        ),
      404 => NotFoundException(
          message: serverMessage ?? 'Resource not found.',
          data: data,
        ),
      408 => RequestTimeoutException(
          message: serverMessage ?? 'Request timed out. Please try again.',
          data: data,
        ),
      409 => ConflictException(
          message: serverMessage ?? 'Conflict. The resource already exists.',
          data: data,
        ),
      422 => UnprocessableEntityException(
          message:
              serverMessage ?? 'Validation failed. Please check your input.',
          data: data,
        ),
      429 => TooManyRequestsException(
          message: serverMessage ?? 'Too many requests. Please slow down.',
          data: data,
        ),
      500 => InternalServerException(
          message:
              serverMessage ?? 'Internal server error. Please try again later.',
          data: data,
        ),
      502 => BadGatewayException(
          message: serverMessage ?? 'Bad gateway. Please try again later.',
          data: data,
        ),
      503 => ServiceUnavailableException(
          message:
              serverMessage ?? 'Service unavailable. Please try again later.',
          data: data,
        ),
      504 => GatewayTimeoutException(
          message: serverMessage ?? 'Gateway timeout. Please try again later.',
          data: data,
        ),
      _ => UnknownApiException(
          message: serverMessage ?? 'Something went wrong. Please try again.',
          statusCode: statusCode,
          data: data,
        ),
    };
  }
}
