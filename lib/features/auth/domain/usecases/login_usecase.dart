import '../entities/auth_tokens_entity.dart';
import '../repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository _repository;
  LoginUseCase(this._repository);

  Future<AuthTokensEntity> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
