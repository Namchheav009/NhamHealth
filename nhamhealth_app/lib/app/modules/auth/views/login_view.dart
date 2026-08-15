import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/login_controller.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/login_form.dart';
import 'forgot_password_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Obx(
        () => LoginForm(
          emailController: _emailController,
          passwordController: _passwordController,
          loading: _controller.isLoading.value,
          onLogin:
              () => _controller.login(
                _emailController.text,
                _passwordController.text,
              ),
          onGoogle: _controller.loginWithGoogle,
          onGoogleAuthenticated: _controller.loginWithGoogleToken,
          onForgotPassword:
              () => Get.to(
                () => ForgotPasswordPage(),
                transition: Transition.rightToLeft,
              ),
          onRegister: () => Get.offNamed(AppRoutes.register),
        ),
      ),
    );
  }
}
