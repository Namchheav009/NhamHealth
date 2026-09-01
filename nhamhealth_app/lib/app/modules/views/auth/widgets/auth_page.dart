import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/login_controller.dart';
import '../../../controllers/auth/register_controller.dart';
import '../forgot_password_view.dart';
import 'auth_scaffold.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late int _selectedIndex;

  LoginController get _login => Get.find<LoginController>();
  RegisterController get _register => Get.find<RegisterController>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Obx(
        () => IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.loose,
          children: [
            LoginForm(
              emailController: _login.emailController,
              passwordController: _login.passwordController,
              loading: _login.isLoading.value,
              onLogin: _login.submit,
              onGoogle: _login.loginWithGoogle,
              onGoogleAuthenticated: _login.loginWithGoogleToken,
              onForgotPassword:
                  () => Get.to(
                    () => ForgotPasswordPage(),
                    transition: Transition.rightToLeft,
                  ),
              onRegister: () => _select(1),
            ),
            RegisterForm(
              fullNameController: _register.fullNameController,
              emailController: _register.emailController,
              passwordController: _register.passwordController,
              confirmPasswordController: _register.confirmPasswordController,
              loading: _register.isLoading.value,
              onRegister: _register.submit,
              onGoogle: _register.registerWithGoogle,
              onGoogleAuthenticated: _register.registerWithGoogleToken,
              onLogin: () => _select(0),
            ),
          ],
        ),
      ),
    );
  }
}
