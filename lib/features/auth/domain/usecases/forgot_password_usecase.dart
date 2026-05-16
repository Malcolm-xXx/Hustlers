import '../repositories/i_auth_repository.dart';

class ForgotPasswordUseCase {
  final IAuthRepository _repository;
  ForgotPasswordUseCase(this._repository);

  Future<void> call(String email) => _repository.forgotPassword(email);
}
