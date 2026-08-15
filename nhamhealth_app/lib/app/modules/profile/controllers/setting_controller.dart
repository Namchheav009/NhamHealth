import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../auth/services/google_auth_service.dart';
import '../bindings/appearance_binding.dart';
import '../bindings/change_password_binding.dart';
import '../bindings/language_binding.dart';
import '../bindings/terms_privacy_binding.dart';
import '../bindings/help_support_binding.dart';
import '../views/appearance_view.dart';
import '../views/change_password_view.dart';
import '../views/language_view.dart';
import '../views/terms_privacy_view.dart';
import '../views/widgets/logout_dialog.dart';
import '../views/help_support_view.dart';

class SettingsController extends GetxController {
  final selectedLanguage = 'English'.obs;
  final isLoggingOut = false.obs;

  void openPasswordSecurity() {
    Get.to<void>(
      () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void openAppearance() {
    Get.to<void>(
      () => const AppearanceView(),
      binding: AppearanceBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void openLanguage() {
    Get.to<void>(
      () => const LanguageView(),
      binding: LanguageBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void openHelpSupport() {
    Get.to<void>(
      () => const HelpSupportView(),
      binding: HelpSupportBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void openTermsPrivacy() {
    Get.to<void>(
      () => const TermsPrivacyView(),
      binding: TermsPrivacyBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void logout() {
    if (isLoggingOut.value || Get.isDialogOpen == true) return;

    Get.dialog<void>(
      LogoutDialog(onLogout: confirmLogout),
      barrierColor: Colors.black.withValues(alpha: 0.32),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 180),
      transitionCurve: Curves.easeOut,
    );
  }

  Future<void> confirmLogout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    if (Get.isDialogOpen == true) Get.back<void>();

    try {
      await Get.find<AuthService>().logout();

      if (Get.isRegistered<GoogleAuthService>()) {
        try {
          await Get.find<GoogleAuthService>().signOut();
        } on Object {
          // The local session is already cleared.
        }
      }

      Get.offAllNamed<void>(AppRoutes.login);
    } on Object {
      Get.snackbar(
        'Logout failed',
        'Unable to clear your session. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  void goBack() {
    Get.back();
  }
}
