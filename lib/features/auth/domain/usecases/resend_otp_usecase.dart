import '../repositories/i_auth_repository.dart';

class ResendOtpUseCase {
  final IAuthRepository _repository;
  ResendOtpUseCase(this._repository);

  Future<void> call(String email) => _repository.resendEmailOtp(email);
}
