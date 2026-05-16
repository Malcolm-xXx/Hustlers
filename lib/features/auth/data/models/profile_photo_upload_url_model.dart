class ProfilePhotoUploadUrlModel {
  final String uploadUrl;
  final String publicId;
  final String signature;
  final int timestamp;
  final String apiKey;

  const ProfilePhotoUploadUrlModel({
    required this.uploadUrl,
    required this.publicId,
    required this.signature,
    required this.timestamp,
    required this.apiKey,
  });

  factory ProfilePhotoUploadUrlModel.fromJson(Map<String, dynamic> json) {
    return ProfilePhotoUploadUrlModel(
      uploadUrl: json['upload_url'] as String,
      publicId: json['public_id'] as String,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      apiKey: json['api_key'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'upload_url': uploadUrl,
        'public_id': publicId,
        'signature': signature,
        'timestamp': timestamp,
        'api_key': apiKey,
      };
}
