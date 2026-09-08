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
              ? 'auth.enter_your_email_or_phone_number'.tr
              : 'auth.please_enter_a_valid_email_or_phone_number'.tr;
      return;
    }

    try {
      isLoading.value = true;
      await _authService.requestPasswordReset(value);
      AppAlert.success(
        title: isPhone ? 'auth.check_your_messages' : 'auth.check_your_email',
        message:
            isPhone
                ? 'auth.if_an_account_exists_for_this_phone_number_the_code_is_on_its_way'
                : 'auth.if_an_account_exists_for_this_email_the_code_is_on_its_way',
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
      title: 'common.forgot_password',
      subtitle:
          'auth.enter_your_email_address_or_phone_number_to_receive_a_code',
      illustrationAsset: 'assets/images/auth/forgot_password.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => AuthTextField(
              key: const ValueKey<String>('forgot-password-identifier-field'),
              controller: controller.emailOrPhoneController,
              hintText: 'auth.email_address_or_phone_number',
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
              label: 'auth.send_code',
              loading: controller.isLoading.value,
              onPressed: controller.sendCode,
            ),
          ),
        ],
      ),
    );
  }
}
