import '../repositories/i_auth_repository.dart';

class VerifyPasswordResetOtpUseCase {
  final IAuthRepository _repository;
  VerifyPasswordResetOtpUseCase(this._repository);

  /// Returns the verification token to pass to [ConfirmPasswordResetUseCase].
  Future<String> call({required String email, required String otp}) {
    return _repository.verifyPasswordResetOtp(email: email, otp: otp);
  }
}
