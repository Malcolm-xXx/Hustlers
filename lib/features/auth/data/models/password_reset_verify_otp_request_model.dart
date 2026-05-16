class PasswordResetVerifyOtpRequestModel {
  final String email;
  final String otp;

  const PasswordResetVerifyOtpRequestModel({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
      };
}
