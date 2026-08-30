import 'package:flutter/material.dart';
import 'widgets/auth_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthPage(initialIndex: 0);
}
