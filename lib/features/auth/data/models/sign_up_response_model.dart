class SignUpResponseModel {
  final String userId;
  final String accessToken;
  final String refreshToken;

  const SignUpResponseModel({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SignUpResponseModel(
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
