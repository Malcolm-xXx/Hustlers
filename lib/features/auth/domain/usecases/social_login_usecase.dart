import '../entities/auth_tokens_entity.dart';
import '../repositories/i_auth_repository.dart';

class SocialLoginUseCase {
  final IAuthRepository _repository;
  SocialLoginUseCase(this._repository);

  Future<AuthTokensEntity> call({required String idToken}) {
    return _repository.googleLogin(idToken: idToken);
  }
}
