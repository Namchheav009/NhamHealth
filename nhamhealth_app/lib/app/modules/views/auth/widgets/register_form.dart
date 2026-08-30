import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import 'auth_tab_switcher.dart';
import 'password_field.dart';
import 'platform_google_sign_in_button.dart';
import 'social_login_button.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.loading,
    required this.onRegister,
    required this.onGoogle,
    required this.onGoogleAuthenticated,
    required this.onLogin,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final VoidCallback onRegister;
  final VoidCallback onGoogle;
  final ValueChanged<String> onGoogleAuthenticated;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTabSwitcher(
            selectedIndex: 1,
            onLogin: onLogin,
            onRegister: () {},
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 5),
          Text(
            'Start building healthier habits with NhamHealth.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            controller: fullNameController,
            hintText: 'Full name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: emailController,
            hintText: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 10),
          PasswordField(
            controller: passwordController,
            hintText: 'Password',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 10),
          PasswordField(
            controller: confirmPasswordController,
            hintText: 'Confirm password',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => onRegister(),
          ),
          const SizedBox(height: 13),
          AuthPrimaryButton(
            label: 'Sign Up',
            loading: loading,
            onPressed: onRegister,
          ),
          const SizedBox(height: 10),
          PlatformGoogleSignInButton(
            label: 'Continue with Google',
            loading: loading,
            onPressed: onGoogle,
            onAuthenticated: onGoogleAuthenticated,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Already have an account?'.tr,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: loading ? null : onLogin,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign In'.tr,
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
