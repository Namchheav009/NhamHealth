import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/app_security_service.dart';
import '../models/google_login_request.dart';
import '../models/register_request.dart';
import '../services/google_auth_service.dart';
import '../views/verification_view.dart';

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
      await _authService.register(
        RegisterRequest(fullName: fullName, email: email, password: password),
      );
      Get.to(
        () => const VerificationView(),
        arguments: {
          'email': email.trim().toLowerCase(),
          'purpose': 'registration',
        },
        transition: Transition.rightToLeft,
      );
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
    final security = Get.find<AppSecurityService>();
    security.syncPinState(response.user.hasPin);
    if (!response.user.hasPin) {
      await security.markSetupPendingFor(response.user.id);
    }
    Get.offAllNamed(AppRoutes.accountCreated, arguments: response.user);
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
    AppAlert.error(title: 'Sign up failed', message: message);
  }
}
