import 'dart:io';
import '../datasources/verification_remote_datasource.dart';
import '../../domain/repositories/i_verification_repository.dart';

class VerificationRepositoryImpl implements IVerificationRepository {
  final VerificationRemoteDatasource _datasource;

  VerificationRepositoryImpl(this._datasource);

  @override
  Future<Map<String, dynamic>> getVerificationStatus() async {
    return _datasource.getStatus();
  }

  @override
  Future<(String url, String publicId)> uploadVerificationImage(File imageFile) async {
    // 1. Get presigned URL
    final uploadInfo = await _datasource.getPresignedUrl('image/jpeg');
    
    // The spec (PresignedUploadResponse) has 'upload_url' and 'public_id'
    final data = uploadInfo['data'] ?? uploadInfo;
    final url = data['upload_url'] as String;
    final publicId = data['public_id'] as String;

    // 2. Upload binary
    await _datasource.uploadBinaryFile(url, imageFile);

    return (url, publicId);
  }

  @override
  Future<void> submitVerification({
    required String idType,
    required String idImageUrl,
    required String idImagePublicId,
    required String selfieImageUrl,
    required String selfieImagePublicId,
  }) async {
    await _datasource.submitVerification({
      'id_type': idType,
      'id_image_url': idImageUrl,
      'id_image_public_id': idImagePublicId,
      'selfie_image_url': selfieImageUrl,
      'selfie_image_public_id': selfieImagePublicId,
    });
  }
}
