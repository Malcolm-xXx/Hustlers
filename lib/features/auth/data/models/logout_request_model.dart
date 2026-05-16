class LogoutRequestModel {
  final String refreshToken;

  const LogoutRequestModel({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
