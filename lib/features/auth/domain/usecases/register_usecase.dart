import '../repositories/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository _repository;
  RegisterUseCase(this._repository);

  Future<void> call({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
