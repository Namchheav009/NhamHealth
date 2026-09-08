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
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

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
  final RxnString identifierError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString submitError = RxnString();
  final RxBool credentialsInvalid = false.obs;

  Future<void> login(String identifier, String password) async {
    _clearErrors();
    final normalized = identifier.trim();
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
    if (password.isEmpty) {
      passwordError.value = 'Enter your password.';
    }
    if (identifierError.value != null || passwordError.value != null) {
      return;
    }

    await _run(
      () async {
        final response = await _authService.login(
          LoginRequest(email: normalized, password: password),
        );
        await _finishLogin(response.user);
      },
      onLoginOtpRequired:
          (challenge) => _openLoginVerification(
            challenge.email.isEmpty ? normalized : challenge.email,
          ),
      onLoginOtpDeliveryPending:
          (pending) => _openLoginVerification(
            pending.email.isEmpty ? normalized : pending.email,
            deliveryPending: true,
          ),
      onError: _handleLoginError,
    );
  }

  void clearIdentifierError(String _) {
    identifierError.value = null;
    credentialsInvalid.value = false;
    submitError.value = null;
  }

  void clearPasswordError(String _) {
    passwordError.value = null;
    credentialsInvalid.value = false;
    submitError.value = null;
  }

  void _openLoginVerification(String email, {bool deliveryPending = false}) {
    Get.to(
      () => const VerificationView(),
      arguments: {
        'email': email,
        'purpose': 'login',
        'deliveryPending': deliveryPending,
      },
      transition: Transition.rightToLeft,
    );
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

  Future<void> _run(
    Future<void> Function() action, {
    ValueChanged<LoginOtpRequiredException>? onLoginOtpRequired,
    ValueChanged<LoginOtpDeliveryPendingException>? onLoginOtpDeliveryPending,
    ValueChanged<Object>? onError,
  }) async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      await action();
    } on LoginOtpRequiredException catch (challenge) {
      if (onLoginOtpRequired != null) {
        onLoginOtpRequired(challenge);
      } else {
        _showError(challenge.message);
      }
    } on LoginOtpDeliveryPendingException catch (pending) {
      if (onLoginOtpDeliveryPending != null) {
        onLoginOtpDeliveryPending(pending);
      } else {
        _showError(pending.message);
      }
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

  void _handleLoginError(Object error) {
    if (error is AuthException && error.statusCode == 401) {
      credentialsInvalid.value = true;
      submitError.value = 'The email/phone number or password is incorrect.';
      return;
    }
    submitError.value =
        error is AuthException ? error.message : error.toString();
  }

  void _clearErrors() {
    identifierError.value = null;
    passwordError.value = null;
    submitError.value = null;
    credentialsInvalid.value = false;
  }

  void _showError(String message) {
    AppAlert.error(title: 'auth.sign_in_failed'.tr, message: message.trOrSelf);
  }
}
