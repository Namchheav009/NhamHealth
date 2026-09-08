import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import 'widgets/auth_flow_scaffold.dart';
import 'widgets/social_login_button.dart';

class PasswordSuccessController extends GetxController {
  void backToLogin() => Get.offAllNamed(AppRoutes.login);
}

class PasswordSuccessView extends StatelessWidget {
  const PasswordSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PasswordSuccessController());

    return AuthFlowScaffold(
      title: 'auth.password_changed',
      subtitle: 'auth.your_account_is_ready_to_use_again',
      illustrationAsset: 'assets/images/auth/account_create.png',
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'auth.your_password_has_been_reset_successfully'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'auth.back_to_sign_in',
            loading: false,
            onPressed: controller.backToLogin,
          ),
        ],
      ),
    );
  }
}
