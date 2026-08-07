import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../models/google_login_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/google_auth_service.dart';

class RegisterController extends GetxController {
  RegisterController({AuthService? authService, GoogleAuthService? googleAuth})
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

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (fullName.trim().length < 2) {
      _showError('Please enter your full name.');
      return;
    }
    if (!GetUtils.isEmail(email.trim())) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must contain at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showError('The passwords do not match.');
      return;
    }

    await _run(() async {
      try {
        final response = await _authService.register(
          RegisterRequest(fullName: fullName, email: email, password: password),
        );
        Get.offAllNamed(AppRoutes.home, arguments: response.user);
      } on AuthException catch (error) {
        if (error.statusCode != 409) rethrow;

        try {
          final response = await _authService.login(
            LoginRequest(email: email, password: password),
          );
          Get.offAllNamed(AppRoutes.home, arguments: response.user);
        } on AuthException {
          throw const AuthException(
            'This email is already registered. Use your original password '
            'on the Sign In tab, or continue with Google.',
          );
        }
      }
    });
  }

  Future<void> registerWithGoogle() async {
    await _run(() async {
      final idToken = await _googleAuth.signInAndGetIdToken();
      if (idToken == null) return;
      await _registerWithGoogleToken(idToken);
    });
  }

  Future<void> registerWithGoogleToken(String idToken) =>
      _run(() => _registerWithGoogleToken(idToken));

  Future<void> _registerWithGoogleToken(String idToken) async {
    final response = await _authService.loginWithGoogle(
      GoogleLoginRequest(idToken: idToken),
    );
    Get.offAllNamed(AppRoutes.home, arguments: response.user);
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
      'Sign up failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFB3261E),
      colorText: Colors.white,
    );
  }
}
