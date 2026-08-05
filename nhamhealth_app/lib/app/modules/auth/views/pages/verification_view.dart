import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../widgets/auth_flow_scaffold.dart';
import '../widgets/social_login_button.dart';
import 'reset_password_view.dart';

class VerificationController extends GetxController {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
  final RxString userEmailOrPhone = 'Your email or phone'.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['emailOrPhone'] != null) {
      userEmailOrPhone.value = args['emailOrPhone'] as String;
    }
  }

  @override
  void onClose() {
    for (final textController in otpControllers) {
      textController.dispose();
    }
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.onClose();
  }

  void verifyCode() {
    final code = otpControllers.map((item) => item.text).join();
    if (code.length != 4) {
      hasError.value = true;
      return;
    }

    hasError.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
    Get.to(
      () => const ResetPasswordView(),
      arguments: {'emailOrPhone': userEmailOrPhone.value},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void clearError() {
    if (hasError.value) hasError.value = false;
  }

  void resendCode() {
    Get.snackbar(
      'Code sent',
      'A new verification code has been sent.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationController());

    return AuthFlowScaffold(
      title: 'Verification',
      subtitle: 'Enter the four-digit code to continue.',
      illustrationAsset: 'assets/images/Login/verification.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'We sent a code to',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.userEmailOrPhone.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => _OtpBox(
                  controller: controller,
                  index: index,
                  hasError: controller.hasError.value,
                ),
              ),
            ),
          ),
          Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  controller.hasError.value
                      ? const Padding(
                        key: ValueKey('verification-error'),
                        padding: EdgeInsets.only(top: 7),
                        child: Text(
                          'Wrong or incomplete code. Try again.',
                          textAlign: TextAlign.center,
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
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: 'Verify code',
            loading: false,
            onPressed: controller.verifyCode,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Didn't receive the code?",
                style: TextStyle(fontSize: 11, color: AppColors.darkGreen),
              ),
              TextButton(
                onPressed: controller.resendCode,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.accentOrange,
                ),
                child: const Text(
                  'Send again',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.index,
    required this.hasError,
  });

  final VerificationController controller;
  final int index;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 54,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.focusNodes[index],
        keyboardType: TextInputType.number,
        textInputAction:
            index == 3 ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorCoral : Colors.white,
              width: hasError ? 1.4 : 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorCoral : AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (value) {
          controller.clearError();
          if (value.isNotEmpty && index < 3) {
            controller.focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            controller.focusNodes[index - 1].requestFocus();
          } else if (value.isNotEmpty && index == 3) {
            controller.focusNodes[index].unfocus();
          }
        },
        onSubmitted: (_) => controller.verifyCode(),
      ),
    );
  }
}
