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
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerFullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  LoginController get _login => Get.find<LoginController>();
  RegisterController get _register => Get.find<RegisterController>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
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
              emailController: _loginEmailController,
              passwordController: _loginPasswordController,
              loading: _login.isLoading.value,
              onLogin:
                  () => _login.login(
                    _loginEmailController.text,
                    _loginPasswordController.text,
                  ),
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
              fullNameController: _registerFullNameController,
              emailController: _registerEmailController,
              passwordController: _registerPasswordController,
              confirmPasswordController: _registerConfirmPasswordController,
              loading: _register.isLoading.value,
              onRegister:
                  () => _register.register(
                    fullName: _registerFullNameController.text,
                    email: _registerEmailController.text,
                    password: _registerPasswordController.text,
                    confirmPassword: _registerConfirmPasswordController.text,
                  ),
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
