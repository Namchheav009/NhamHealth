import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import 'verification_view.dart';
import 'widgets/auth_flow_scaffold.dart';
import 'widgets/password_field.dart';
import 'widgets/social_login_button.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({AuthService? authService})
    : _authService = authService ?? Get.find<AuthService>();

  final AuthService _authService;
  final TextEditingController emailOrPhoneController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxnString identifierError = RxnString();
  final RxnString submitError = RxnString();

  Future<void> sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    identifierError.value = null;
    submitError.value = null;
    final value = emailOrPhoneController.text.trim();

    final isEmail = GetUtils.isEmail(value);
    final isPhone =
        !value.contains('@') && RegExp(r'^\+?[0-9\s\-]{8,15}$').hasMatch(value);

    if (!isEmail && !isPhone) {
      identifierError.value =
          value.isEmpty
              ? 'Enter your email or phone number.'
              : 'Please enter a valid email or phone number.';
      return;
    }

    try {
      isLoading.value = true;
      await _authService.requestPasswordReset(value);
      AppAlert.success(
        title: isPhone ? 'Check your messages' : 'Check your email',
        message:
            isPhone
                ? 'If an account exists for this phone number, the code is on its way.'
                : 'If an account exists for this email, the code is on its way.',
      );
      Get.to(
        () => const VerificationView(),
        arguments: {'email': value.trim().toLowerCase()},
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } on AuthException catch (error) {
      submitError.value = error.message;
    } finally {
      isLoading.value = false;
    }
  }

  void clearIdentifierError(String _) {
    identifierError.value = null;
    submitError.value = null;
  }

  @override
  void onClose() {
    emailOrPhoneController.dispose();
    super.onClose();
  }
}

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final ForgotPasswordController controller = Get.put(
    ForgotPasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      title: 'Forgot password?',
      subtitle: 'Enter your email address or phone number to receive a code.',
      illustrationAsset: 'assets/images/auth/forgot_password.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => AuthTextField(
              key: const ValueKey<String>('forgot-password-identifier-field'),
              controller: controller.emailOrPhoneController,
              hintText: 'Email address or phone number',
              prefixIcon: Icons.account_circle_outlined,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
                AutofillHints.telephoneNumber,
              ],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: controller.identifierError.value,
              onChanged: controller.clearIdentifierError,
              onSubmitted: (_) => controller.sendCode(),
            ),
          ),
          Obx(() => AuthInlineError(message: controller.submitError.value)),
          const SizedBox(height: 16),
          Obx(
            () => AuthPrimaryButton(
              label: 'Send code',
              loading: controller.isLoading.value,
              onPressed: controller.sendCode,
            ),
          ),
        ],
      ),
    );
  }
}
