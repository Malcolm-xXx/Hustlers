import '../repositories/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository _repository;
  LogoutUseCase(this._repository);

  Future<void> call({required String refreshToken}) {
    return _repository.logout(refreshToken: refreshToken);
  }
}
