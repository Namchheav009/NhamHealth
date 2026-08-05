import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../widgets/auth_flow_scaffold.dart';
import '../widgets/password_field.dart';
import '../widgets/social_login_button.dart';
import 'verification_view.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = emailOrPhoneController.text.trim();

    if (value.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your email or phone number.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    await Future<void>.delayed(const Duration(seconds: 2));
    isLoading.value = false;

    Get.snackbar(
      'Code sent',
      'Verification code sent successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.primaryGreen,
      colorText: Colors.white,
    );

    Get.to(
      () => const VerificationView(),
      arguments: {'emailOrPhone': value},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
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
      subtitle: 'Enter your email or phone number to receive a code.',
      illustrationAsset: 'assets/images/Login/forgot_password.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: controller.emailOrPhoneController,
            hintText: 'Email or Phone number',
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
