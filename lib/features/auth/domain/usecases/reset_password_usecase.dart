import '../repositories/i_auth_repository.dart';

class ResetPasswordUseCase {
  final IAuthRepository _repository;
  ResetPasswordUseCase(this._repository);

  Future<void> call({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _repository.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
