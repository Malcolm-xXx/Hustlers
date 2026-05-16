import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/api_exceptions.dart';
import '../../../../core/services/dio_client.dart';

class VerificationRemoteDatasource {
  final DioClient _dioClient;

  VerificationRemoteDatasource(this._dioClient);

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dioClient.get(ApiConstants.verificationStatus);
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return {'status': 'unverified'};
      }
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<Map<String, dynamic>> getPresignedUrl(String contentType) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.uploadPresigned,
        data: {'content_type': contentType},
      );
      // Spec says PresignedUploadResponse contains upload_url and public_id (or similar)
      // Let's assume the data structure matches PresignedUploadResponse
      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  Future<void> submitVerification(Map<String, dynamic> data) async {
    try {
      await _dioClient.post(
        ApiConstants.verificationSubmit,
        data: data,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }

  // Uses a fresh Dio instance because the upload URL is an external pre-signed URL
  // (e.g. S3) that requires no auth headers and has a different base URL.
  Future<void> uploadBinaryFile(String url, File file) async {
    try {
      final bytes = await file.readAsBytes();
      await Dio().put(
        url,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'image/jpeg',
            HttpHeaders.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw ApiErrorHandler.handle(e);
    } catch (e) {
      throw ApiErrorHandler.handleParseError(e);
    }
  }
}
