import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../bindings/profile/appearance_binding.dart';
import '../../bindings/profile/help_support_binding.dart';
import '../../bindings/profile/language_binding.dart';
import '../../bindings/profile/terms_privacy_binding.dart';
import '../../services/auth/google_auth_service.dart';
import '../../views/profile/appearance_view.dart';
import '../../views/profile/help_support_view.dart';
import '../../views/profile/language_view.dart';
import '../../views/profile/security_view.dart';
import '../../views/profile/terms_privacy_view.dart';
import '../../views/profile/widgets/dynamic_notification_studio_sheet.dart';
import '../../views/profile/widgets/logout_dialog.dart';

class SettingsController extends GetxController {
  final isLoading = true.obs;
  final isLoggingOut = false.obs;
  final isSendingTestAlert = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!isClosed) isLoading.value = false;
  }

  void openPasswordSecurity() {
    Get.to<void>(
      () => const SecurityView(),
      transition: Transition.rightToLeft,
    );
  }

  void openFavorites() {
    Get.toNamed<void>(AppRoutes.favorites);
  }

  void selectBottomMenu(int index) {
    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        return;
      case 1:
        Get.offNamed<void>(AppRoutes.meals);
        return;
      case 2:
        Get.offNamed<void>(AppRoutes.community);
        return;
      case 4:
        return;
    }
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

  void openMyReports() {
    Get.toNamed<void>(AppRoutes.myReports);
  }

  void openTermsPrivacy() {
    Get.to<void>(
      () => const TermsPrivacyView(),
      binding: TermsPrivacyBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void openDynamicNotificationStudio([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      DynamicNotificationStudioSheet.show(ctx);
    }
  }

  Future<void> sendTestNotificationAlert([BuildContext? context]) async {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      DynamicNotificationStudioSheet.show(ctx);
      return;
    }

    if (isSendingTestAlert.value) return;
    isSendingTestAlert.value = true;
    AppAlert.notification(
      title: 'profile.alert_scheduled_title'.tr,
      message: 'profile.alert_sent_toast'.tr,
    );
    try {
      final pushService =
          PushNotificationService.instance ??
          PushNotificationService(authService: Get.find());
      await pushService.showLocalTestNotification(
        title: 'Kun Kaknika',
        body: 'Shared an instant: "How cute 🫣🫶"',
        subText: 'c.zen_03',
        delay: const Duration(seconds: 3),
      );
    } finally {
      isSendingTestAlert.value = false;
    }
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
      AppAlert.error(
        title: 'home.logout_failed',
        message: 'home.logout_failed_help',
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    } else {
      Get.offAllNamed<void>(AppRoutes.home);
    }
  }
}
