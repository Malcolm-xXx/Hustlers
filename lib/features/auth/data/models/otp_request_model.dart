class OtpRequestModel {
  final String email;
  final String otp;

  const OtpRequestModel({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}
