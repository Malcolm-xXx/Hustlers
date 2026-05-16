import '../../domain/entities/auth_tokens_entity.dart';

class AuthTokensModel {
  final String accessToken;
  final String refreshToken;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  // Expects the raw API response body: { "success": true, "data": { "access_token": ..., "refresh_token": ... } }
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthTokensModel(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  AuthTokensEntity toEntity() => AuthTokensEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
