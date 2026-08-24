import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../../core/services/auth_service.dart';
import 'widgets/auth_flow_scaffold.dart';
import 'widgets/password_field.dart';
import 'widgets/social_login_button.dart';
import 'verification_view.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({AuthService? authService})
    : _authService = authService ?? Get.find<AuthService>();

  final AuthService _authService;
  final TextEditingController emailOrPhoneController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = emailOrPhoneController.text.trim();

    if (!GetUtils.isEmail(value)) {
      AppAlert.error(
        title: 'Invalid email',
        message: 'Please enter a valid email address.',
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authService.requestPasswordReset(value);
      AppAlert.success(
        title: 'Check your email',
        message: 'If an account exists for this email, the code is on its way.',
      );
      Get.to(
        () => const VerificationView(),
        arguments: {'email': value.trim().toLowerCase()},
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } on AuthException catch (error) {
      AppAlert.error(title: 'Could not send code', message: error.message);
    } finally {
      isLoading.value = false;
    }
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
      subtitle: 'Enter your email address to receive a code.',
      illustrationAsset: 'assets/images/auth/forgot_password.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: controller.emailOrPhoneController,
            hintText: 'Email address',
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.sendCode(),
          ),
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
