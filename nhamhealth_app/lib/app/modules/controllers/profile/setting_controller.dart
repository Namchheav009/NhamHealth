import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../services/auth/google_auth_service.dart';
import '../../bindings/profile/appearance_binding.dart';
import '../../bindings/profile/language_binding.dart';
import '../../bindings/profile/terms_privacy_binding.dart';
import '../../bindings/profile/help_support_binding.dart';
import '../../views/profile/appearance_view.dart';
import '../../views/profile/security_view.dart';
import '../../views/profile/language_view.dart';
import '../../views/profile/terms_privacy_view.dart';
import '../../views/profile/widgets/logout_dialog.dart';
import '../../views/profile/help_support_view.dart';

class SettingsController extends GetxController {
  final selectedLanguage = 'English'.obs;
  final isLoggingOut = false.obs;

  void openPasswordSecurity() {
    Get.to<void>(
      () => const SecurityView(),
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
      LogoutDialog(onLogout: confirmLogout, isLoading: isLoggingOut),
      barrierColor: Colors.black.withValues(alpha: 0.32),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 180),
      transitionCurve: Curves.easeOut,
    );
  }

  Future<void> confirmLogout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

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
      AppAlert.error(title: 'Logout failed', message: 'Unable to clear your session. Please try again.');
    } finally {
      isLoggingOut.value = false;
    }
  }

  void goBack() {
    Get.back();
  }
}
