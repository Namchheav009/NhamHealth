import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_security_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../models/auth/google_login_request.dart';
import '../../models/auth/register_request.dart';
import '../../services/auth/google_auth_service.dart';
import '../../views/auth/verification_view.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

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
  final RxnString fullNameError = RxnString();
  final RxnString identifierError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString confirmPasswordError = RxnString();
  final RxnString submitError = RxnString();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _clearErrors();
    if (fullName.trim().length < 2) {
      fullNameError.value = 'Please enter your full name.';
    }
    final normalized = email.trim();
    final isEmail = GetUtils.isEmail(normalized);
    final isPhone = RegExp(
      r'^\+?[0-9]{8,15}$',
    ).hasMatch(normalized.replaceAll(RegExp(r'[\s()-]'), ''));
    if (!isEmail && !isPhone) {
      identifierError.value =
          normalized.isEmpty
              ? 'Enter your email or phone number.'
              : 'Please enter a valid email or phone number.';
    }
    if (password.length < 8) {
      passwordError.value = 'Password must contain at least 8 characters.';
    }
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Confirm your password.';
    } else if (password != confirmPassword) {
      confirmPasswordError.value = 'The passwords do not match.';
    }
    if (fullNameError.value != null ||
        identifierError.value != null ||
        passwordError.value != null ||
        confirmPasswordError.value != null) {
      return;
    }

    await _run(() async {
      await _authService.register(
        RegisterRequest(
          fullName: fullName,
          email: normalized,
          password: password,
        ),
      );
      Get.to(
        () => const VerificationView(),
        arguments: {'email': normalized, 'purpose': 'registration'},
        transition: Transition.rightToLeft,
      );
    }, onError: _handleRegistrationError);
  }

  void clearFullNameError(String _) {
    fullNameError.value = null;
    submitError.value = null;
  }

  void clearIdentifierError(String _) {
    identifierError.value = null;
    submitError.value = null;
  }

  void clearPasswordError(String _) {
    passwordError.value = null;
    if (confirmPasswordError.value == 'The passwords do not match.') {
      confirmPasswordError.value = null;
    }
    submitError.value = null;
  }

  void clearConfirmPasswordError(String _) {
    confirmPasswordError.value = null;
    submitError.value = null;
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
    Get.offAllNamed(AppRoutes.accountCreated, arguments: response.user);
  }

  Future<void> _run(
    Future<void> Function() action, {
    ValueChanged<Object>? onError,
  }) async {
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
      if (onError != null) {
        onError(error);
      } else {
        _showError(error.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _handleRegistrationError(Object error) {
    final message = error is AuthException ? error.message : error.toString();
    if (error is AuthException && error.statusCode == 409) {
      identifierError.value = message;
      return;
    }
    submitError.value = message;
  }

  void _clearErrors() {
    fullNameError.value = null;
    identifierError.value = null;
    passwordError.value = null;
    confirmPasswordError.value = null;
    submitError.value = null;
  }

  void _showError(String message) {
    AppAlert.error(title: 'auth.sign_up_failed'.tr, message: message.trOrSelf);
  }
}
