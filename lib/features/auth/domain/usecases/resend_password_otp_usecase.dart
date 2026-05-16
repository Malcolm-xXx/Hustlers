import '../repositories/i_auth_repository.dart';

class ResendPasswordOtpUseCase {
  final IAuthRepository _repository;
  ResendPasswordOtpUseCase(this._repository);

  Future<void> call(String email) => _repository.resendPasswordOtp(email);
}
