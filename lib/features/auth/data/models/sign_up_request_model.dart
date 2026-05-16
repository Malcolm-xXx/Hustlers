class SignUpRequestModel {
  final String name;
  final String phone;
  final String email;
  final String password;
  final String? role;
  final String? nin;

  const SignUpRequestModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    this.role,
    this.nin,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      if (role != null) 'role': role,
      if (nin != null) 'nin': nin,
    };
  }
}
