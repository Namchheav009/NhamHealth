import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import 'widgets/auth_flow_scaffold.dart';
import 'widgets/password_field.dart';
import 'widgets/social_login_button.dart';
import 'password_success_view.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({AuthService? authService})
    : _authService = authService ?? Get.find<AuthService>();

  final AuthService _authService;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final RxnString newPasswordError = RxnString();
  final RxnString confirmPasswordError = RxnString();
  final RxnString submitError = RxnString();
  final RxBool isLoading = false.obs;
  late final String resetToken;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    resetToken =
        args is Map && args['resetToken'] is String
            ? args['resetToken'] as String
            : '';
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    newPasswordError.value = null;
    confirmPasswordError.value = null;
    submitError.value = null;

    if (newPassword.isEmpty) {
      newPasswordError.value = 'Enter a new password.';
    } else if (newPassword.length < 8) {
      newPasswordError.value =
          'Use at least 8 characters for your new password.';
    }
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Confirm your password.';
    } else if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match. Try again.';
    }
    if (newPasswordError.value != null || confirmPasswordError.value != null) {
      return;
    }

    if (resetToken.isEmpty) {
      submitError.value = 'Request a new verification code and try again.';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    try {
      isLoading.value = true;
      await _authService.resetPassword(
        resetToken: resetToken,
        newPassword: newPassword,
      );
      Get.offAll(
        () => const PasswordSuccessView(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } on AuthException catch (error) {
      submitError.value = error.message;
    } finally {
      isLoading.value = false;
    }
  }

  void clearNewPasswordError(String _) {
    newPasswordError.value = null;
    if (confirmPasswordError.value == 'Passwords do not match. Try again.') {
      confirmPasswordError.value = null;
    }
    submitError.value = null;
  }

  void clearConfirmPasswordError(String _) {
    confirmPasswordError.value = null;
    submitError.value = null;
  }

  void skip() {
    Get.offAllNamed(AppRoutes.login);
  }
}

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ResetPasswordController());

    return AuthFlowScaffold(
      title: 'Set new password',
      subtitle: 'Choose a strong password for your account.',
      illustrationAsset: 'assets/images/auth/reset.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => PasswordField(
              key: const ValueKey<String>('reset-new-password-field'),
              controller: controller.newPasswordController,
              hintText: 'New password',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              errorText: controller.newPasswordError.value,
              onChanged: controller.clearNewPasswordError,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => PasswordField(
              key: const ValueKey<String>('reset-confirm-password-field'),
              controller: controller.confirmPasswordController,
              hintText: 'Confirm password',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              errorText: controller.confirmPasswordError.value,
              onChanged: controller.clearConfirmPasswordError,
              onSubmitted: (_) => controller.resetPassword(),
            ),
          ),
          Obx(() => AuthInlineError(message: controller.submitError.value)),
          const SizedBox(height: 18),
          Obx(
            () => AuthPrimaryButton(
              label: 'Reset password',
              loading: controller.isLoading.value,
              onPressed: controller.resetPassword,
            ),
          ),
          const SizedBox(height: 10),
          AuthSecondaryButton(
            label: 'Back to sign in',
            onPressed: controller.skip,
          ),
        ],
      ),
    );
  }
}
