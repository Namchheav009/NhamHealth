import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../../core/services/auth_service.dart';
import '../../views/auth/forgot_password_view.dart';

class ChangePasswordController extends GetxController {
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
    final currentPassword = currentPasswordController.text;

    final newPassword = newPasswordController.text;

    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      AppAlert.error(
        title: 'Required',
        message: 'Please complete all password fields.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppAlert.error(
        title: 'Password does not match',
        message: 'Please confirm your new password correctly.',
      );
      return;
    }

    if (newPassword.length < 8) {
      AppAlert.error(
        title: 'Password too short',
        message: 'Use at least 8 characters.',
      );
      return;
    }

    if (newPassword == currentPassword) {
      AppAlert.error(
        title: 'Choose a new password',
        message:
            'Your new password must be different from your current password.',
      );
      return;
    }

    try {
      isLoading.value = true;

      await Get.find<AuthService>().changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      AppAlert.success(
        title: 'Password updated',
        message: 'Your password has been updated.',
      );
    } on AuthException catch (error) {
      AppAlert.error(
        title: 'Could not update password',
        message: error.message,
      );
    } on Object {
      AppAlert.error(
        title: 'Could not update password',
        message: 'Something went wrong. Please try again.',
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
