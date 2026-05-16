import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class GetMeUseCase {
  final IAuthRepository _repository;
  GetMeUseCase(this._repository);

  Future<UserEntity> call() => _repository.getMe();
}
