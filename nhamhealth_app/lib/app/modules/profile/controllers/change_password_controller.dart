import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../auth/views/forgot_password_view.dart';

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
      Get.snackbar(
        'Required',
        'Please complete all password fields.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        'Password does not match',
        'Please confirm your new password correctly.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword.length < 8) {
      Get.snackbar(
        'Password too short',
        'Use at least 8 characters.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword == currentPassword) {
      Get.snackbar(
        'Choose a new password',
        'Your new password must be different from your current password.',
        snackPosition: SnackPosition.BOTTOM,
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

      Get.snackbar(
        'Success',
        'Your password has been updated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF009B43),
        colorText: Colors.white,
      );
    } on AuthException catch (error) {
      Get.snackbar(
        'Could not update password',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Object {
      Get.snackbar(
        'Could not update password',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
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
