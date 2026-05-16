import '../entities/auth_tokens_entity.dart';
import '../repositories/i_auth_repository.dart';

class VerifyOtpUseCase {
  final IAuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  Future<AuthTokensEntity> call({
    required String email,
    required String otp,
  }) {
    return _repository.verifyEmailOtp(email: email, otp: otp);
  }
}
