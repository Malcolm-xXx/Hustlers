import '../repositories/i_auth_repository.dart';

class RefreshTokenUseCase {
  final IAuthRepository _repository;
  RefreshTokenUseCase(this._repository);

  Future<String> call(String refreshToken) =>
      _repository.refreshAccessToken(refreshToken);
}
