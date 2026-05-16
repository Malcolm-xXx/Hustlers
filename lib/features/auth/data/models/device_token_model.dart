import '../../domain/entities/device_token_entity.dart';

class DeviceTokenModel {
  final String id;
  final String token;
  final String platform;

  const DeviceTokenModel({
    required this.id,
    required this.token,
    required this.platform,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
    );
  }

  DeviceTokenEntity toEntity() {
    return DeviceTokenEntity(
      id: id,
      token: token,
      platform: platform,
    );
  }
}
