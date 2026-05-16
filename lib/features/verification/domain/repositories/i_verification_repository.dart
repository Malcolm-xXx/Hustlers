import 'dart:io';

abstract class IVerificationRepository {
  Future<Map<String, dynamic>> getVerificationStatus();
  
  Future<(String url, String publicId)> uploadVerificationImage(File imageFile);

  Future<void> submitVerification({
    required String idType,
    required String idImageUrl,
    required String idImagePublicId,
    required String selfieImageUrl,
    required String selfieImagePublicId,
  });
}
