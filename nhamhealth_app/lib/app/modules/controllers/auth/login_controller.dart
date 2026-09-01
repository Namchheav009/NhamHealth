import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/auth/google_login_request.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../services/auth/google_auth_service.dart';
import '../../../../core/services/app_security_service.dart';
import '../../views/profile/security_view.dart';
import '../../../widgets/pin_setup_prompt.dart';

class LoginController extends GetxController {
  LoginController({AuthService? authService, GoogleAuthService? googleAuth})
    : _authService =
          authService ??
          (Get.isRegistered<AuthService>()
              ? Get.find<AuthService>()
              : AuthService()),
      _googleAuth =
          googleAuth ??
          (Get.isRegistered<GoogleAuthService>()
              ? Get.find<GoogleAuthService>()
              : GoogleAuthService());

  final AuthService _authService;
  final GoogleAuthService _googleAuth;
  final RxBool isLoading = false.obs;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> submit() => login(emailController.text, passwordController.text);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login(String email, String password) async {
    final normalizedEmail = email.trim();
    if (!GetUtils.isEmail(normalizedEmail)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    await _run(() async {
      final response = await _authService.login(
        LoginRequest(email: normalizedEmail, password: password),
      );
      await _finishLogin(response.user);
    });
  }

  Future<void> loginWithGoogle() async {
    await _run(() async {
      final idToken = await _googleAuth.signInAndGetIdToken();
      if (idToken == null) return;
      await _loginWithGoogleToken(idToken);
    });
  }

  Future<void> loginWithGoogleToken(String idToken) =>
      _run(() => _loginWithGoogleToken(idToken));

  Future<void> _loginWithGoogleToken(String idToken) async {
    final response = await _authService.loginWithGoogle(
      GoogleLoginRequest(idToken: idToken),
    );
    await _finishLogin(response.user);
  }

  Future<void> _finishLogin(AuthenticatedUser user) async {
    final security = Get.find<AppSecurityService>();
    security.syncPinState(user.hasPin);
    if (user.hasPin) {
      Get.offAllNamed(AppRoutes.home, arguments: user);
      return;
    }
    if (Get.context != null) {
      await showPinSetupPrompt(Get.context!);
    }
    Get.offAll<void>(
      () => SecurityView(
        promptCreatePin: true,
        requirePinCreation: true,
        onPinCreated: () => Get.offAllNamed(AppRoutes.home, arguments: user),
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      await action();
    } catch (error) {
      _showError(error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    AppAlert.error(title: 'Sign in failed', message: message);
  }
}
