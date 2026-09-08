import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/privacy_auth_dialog.dart';
import '../../views/auth/forgot_password_view.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController({
    AuthService? authService,
    Future<bool> Function(String reason)? authorize,
  }) : _authService = authService,
       _authorize =
           authorize ?? ((reason) => PrivacyAuth.require(reason: reason));

  final AuthService? _authService;
  final Future<bool> Function(String reason) _authorize;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final hideCurrentPassword = true.obs;
  final hideNewPassword = true.obs;
  final hideConfirmPassword = true.obs;

  final isLoading = false.obs;

  void toggleCurrentPassword() {
    hideCurrentPassword.toggle();
  }

  void toggleNewPassword() {
    hideNewPassword.toggle();
  }

  void toggleConfirmPassword() {
    hideConfirmPassword.toggle();
  }

  void forgotPassword() {
    Get.to<void>(() => ForgotPasswordPage());
  }

  Future<void> updatePassword() async {
    if (isLoading.value) return;

    final currentPassword = currentPasswordController.text;

    final newPassword = newPasswordController.text;

    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      await AppAlert.actionError(
        title: 'common.required',
        message: 'profile.please_complete_all_password_fields',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      await AppAlert.actionError(
        title: 'profile.password_does_not_match',
        message: 'profile.please_confirm_your_new_password_correctly',
      );
      return;
    }

    if (newPassword.length < 8) {
      await AppAlert.actionError(
        title: 'profile.password_too_short',
        message: 'profile.use_at_least_8_characters',
      );
      return;
    }

    if (newPassword == currentPassword) {
      await AppAlert.actionError(
        title: 'profile.choose_a_new_password',
        message:
            'profile.your_new_password_must_be_different_from_your_current_password',
      );
      return;
    }

    isLoading.value = true;
    try {
      if (!await _authorize('Unlock to update your account password.')) return;

      await (_authService ?? Get.find<AuthService>()).changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      await AppAlert.actionSuccess(
        title: 'profile.password_updated',
        message: 'profile.your_password_has_been_updated',
      );
    } on AuthException catch (error) {
      await AppAlert.actionError(
        title: 'profile.could_not_update_password',
        message: error.message,
      );
    } on Object {
      await AppAlert.actionError(
        title: 'profile.could_not_update_password',
        message: 'profile.something_went_wrong_please_try_again',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.onClose();
  }
}
