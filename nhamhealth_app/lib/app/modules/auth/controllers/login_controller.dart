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
    final security = Get.find<AppSecurityService>();
    security.syncPinState(user.hasPin);
    if (user.hasPin) {
      Get.offAllNamed(AppRoutes.home, arguments: user);
      return;
    }
    Get.offAll<void>(
      () => SecurityView(
        promptCreatePin: true,
        requirePinCreation: true,
        onPinCreated:
            () => Get.offAllNamed(AppRoutes.home, arguments: user),
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
