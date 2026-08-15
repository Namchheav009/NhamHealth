import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    // Example:
    // Get.toNamed(AppRoutes.forgotPassword);
  }

  Future<void> updatePassword() async {
    final currentPassword =
        currentPasswordController.text.trim();

    final newPassword =
        newPasswordController.text.trim();

    final confirmPassword =
        confirmPasswordController.text.trim();

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

    try {
      isLoading.value = true;

      // Connect API here later.
      await Future.delayed(
        const Duration(seconds: 1),
      );

      Get.snackbar(
        'Success',
        'Your password has been updated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF009B43),
        colorText: Colors.white,
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