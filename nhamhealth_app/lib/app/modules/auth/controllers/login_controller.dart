import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../models/google_login_request.dart';
import '../models/login_request.dart';
import '../models/authenticated_user_model.dart';
import '../services/google_auth_service.dart';
import '../../../../core/services/app_security_service.dart';
import '../../profile/views/security_view.dart';

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
    Get.offAllNamed(AppRoutes.home, arguments: user);
    final security = Get.find<AppSecurityService>();
    final isNewUser = await security.isSetupPendingFor(user.id);
    if (!isNewUser ||
        await security.hasPin ||
        await security.wasSetupPromptedFor(user.id)) {
      return;
    }
    await security.markSetupPromptedFor(user.id);
    await security.clearSetupPendingFor(user.id);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (Get.context == null) return;
    final setUp = await Get.dialog<bool>(
      AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F7EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.security_rounded,
            color: Color(0xFF009B43),
            size: 32,
          ),
        ),
        title: const Text('Protect your health data'),
        content: const Text(
          'Set up a 4-digit PIN and fingerprint or Face ID for safer access to AI Food Check and profile changes.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Set up now'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (setUp == true) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Get.to<void>(
        () => const SecurityView(),
        transition: Transition.rightToLeft,
      );
    }
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
    Get.snackbar(
      'Sign in failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFB3261E),
      colorText: Colors.white,
    );
  }
}
