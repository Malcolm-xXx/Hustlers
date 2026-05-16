class DeviceTokenRequestModel {
  final String token;
  final String platform;

  const DeviceTokenRequestModel({
    required this.token,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
    };
  }
}
