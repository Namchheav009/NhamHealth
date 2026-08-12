import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../routes/app_routes.dart';
import '../widgets/auth_flow_scaffold.dart';
import '../widgets/password_field.dart';
import '../widgets/social_login_button.dart';
import 'account_created_view.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({AuthService? authService})
    : _authService = authService ?? Get.find<AuthService>();

  final AuthService _authService;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final RxBool confirmPasswordHasError = false.obs;
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
    confirmPasswordHasError.value = false;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Required',
        'Please fill in both password fields.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword.length < 8) {
      Get.snackbar(
        'Password too short',
        'Use at least 8 characters for your new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      confirmPasswordHasError.value = true;
      return;
    }

    if (resetToken.isEmpty) {
      Get.snackbar(
        'Reset session expired',
        'Request a new verification code and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Could not reset password',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorCoral,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearConfirmError(String _) {
    if (confirmPasswordHasError.value) {
      confirmPasswordHasError.value = false;
    }
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
      illustrationAsset: 'assets/images/Login/reset.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PasswordField(
            controller: controller.newPasswordController,
            hintText: 'New password',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 10),
          Obx(
            () => PasswordField(
              controller: controller.confirmPasswordController,
              hintText: 'Confirm password',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              hasError: controller.confirmPasswordHasError.value,
              onChanged: controller.clearConfirmError,
              onSubmitted: (_) => controller.resetPassword(),
            ),
          ),
          Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  controller.confirmPasswordHasError.value
                      ? const Padding(
                        key: ValueKey('confirm-password-error'),
                        padding: EdgeInsets.only(top: 6, left: 16),
                        child: Text(
                          'Passwords do not match. Try again.',
                          style: TextStyle(
                            color: AppColors.errorCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
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
