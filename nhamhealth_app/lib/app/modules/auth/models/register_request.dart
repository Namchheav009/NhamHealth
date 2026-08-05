class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'fullName': fullName.trim(),
    'email': email.trim().toLowerCase(),
    'password': password,
  };
}
