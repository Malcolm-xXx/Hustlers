class ResetPasswordRequestModel {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequestModel({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };
}
