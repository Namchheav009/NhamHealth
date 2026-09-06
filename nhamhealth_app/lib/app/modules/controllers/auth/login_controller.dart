import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_security_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/auth/google_login_request.dart';
import '../../models/auth/login_request.dart';
import '../../services/auth/google_auth_service.dart';
import '../../views/auth/verification_view.dart';

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
    final normalized = email.trim();
    final isEmail = GetUtils.isEmail(normalized);
    final isPhone = RegExp(
      r'^\+?[0-9]{8,15}$',
    ).hasMatch(normalized.replaceAll(RegExp(r'[\s()-]'), ''));
    if (!isEmail && !isPhone) {
      _showError('Please enter a valid email or phone number.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    await _run(() async {
      try {
        final response = await _authService.login(
          LoginRequest(email: normalized, password: password),
        );
        await _finishLogin(response.user);
      } on LoginOtpRequiredException catch (challenge) {
        Get.to(
          () => const VerificationView(),
          arguments: {
            'email': challenge.email.isEmpty ? normalized : challenge.email,
            'purpose': 'login',
          },
          transition: Transition.rightToLeft,
        );
      }
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
    Get.offAllNamed(AppRoutes.home, arguments: user);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      await action();
    } on RegistrationOtpRequiredException catch (challenge) {
      Get.to(
        () => const VerificationView(),
        arguments: {'email': challenge.email, 'purpose': 'registration'},
        transition: Transition.rightToLeft,
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    AppAlert.error(title: 'Sign in failed'.tr, message: message.tr);
  }
}
