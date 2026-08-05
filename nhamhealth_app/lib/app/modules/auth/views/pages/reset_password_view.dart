import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../widgets/auth_flow_scaffold.dart';
import '../widgets/password_field.dart';
import '../widgets/social_login_button.dart';
import 'account_created_view.dart';

class ResetPasswordController extends GetxController {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final RxBool confirmPasswordHasError = false.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void resetPassword() {
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

    if (newPassword != confirmPassword) {
      confirmPasswordHasError.value = true;
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    Get.offAll(
      () => const PasswordSuccessView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void clearConfirmError(String _) {
    if (confirmPasswordHasError.value) {
      confirmPasswordHasError.value = false;
    }
  }

  void skip() {
    Get.offAll(
      () => const PasswordSuccessView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
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
          AuthPrimaryButton(
            label: 'Reset password',
            loading: false,
            onPressed: controller.resetPassword,
          ),
          const SizedBox(height: 10),
          AuthSecondaryButton(label: 'Skip', onPressed: controller.skip),
        ],
      ),
    );
  }
}
