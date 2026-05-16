class RegisterRequestModel {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterRequestModel({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phoneNumber,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      };
}
