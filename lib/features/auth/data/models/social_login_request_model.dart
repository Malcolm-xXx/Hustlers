class SocialLoginRequestModel {
  final String idToken;

  const SocialLoginRequestModel({required this.idToken});

  Map<String, dynamic> toJson() => {'id_token': idToken};
}
