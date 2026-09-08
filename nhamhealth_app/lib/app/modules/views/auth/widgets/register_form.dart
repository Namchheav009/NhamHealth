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
    required this.fullNameError,
    required this.identifierError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.submitError,
    required this.onRegister,
    required this.onFullNameChanged,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onGoogle,
    required this.onGoogleAuthenticated,
    required this.onLogin,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final String? fullNameError;
  final String? identifierError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? submitError;
  final VoidCallback onRegister;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onIdentifierChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
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
            'auth.start_building_healthier_habits_with_nhamhealth'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMutedText, fontSize: 12),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            key: const ValueKey<String>('register-full-name-field'),
            controller: fullNameController,
            hintText: 'auth.full_name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: fullNameError,
            onChanged: onFullNameChanged,
          ),
          const SizedBox(height: 10),
          AuthTextField(
            key: const ValueKey<String>('register-identifier-field'),
            controller: emailController,
            hintText: 'auth.email_or_phone_number'.tr,
            prefixIcon: Icons.account_circle_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
              AutofillHints.telephoneNumber,
            ],
            errorText: identifierError,
            onChanged: onIdentifierChanged,
          ),
          const SizedBox(height: 10),
          PasswordField(
            key: const ValueKey<String>('register-password-field'),
            controller: passwordController,
            hintText: 'auth.password',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            errorText: passwordError,
            onChanged: onPasswordChanged,
          ),
          const SizedBox(height: 10),
          PasswordField(
            key: const ValueKey<String>('register-confirm-password-field'),
            controller: confirmPasswordController,
            hintText: 'auth.confirm_password',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            errorText: confirmPasswordError,
            onChanged: onConfirmPasswordChanged,
            onSubmitted: (_) => onRegister(),
          ),
          AuthInlineError(message: submitError),
          const SizedBox(height: 13),
          AuthPrimaryButton(
            label: 'auth.sign_up',
            loading: loading,
            onPressed: onRegister,
          ),
          const SizedBox(height: 10),
          PlatformGoogleSignInButton(
            label: 'auth.continue_with_google',
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
                  'auth.already_have_an_account'.tr,
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
                  'auth.sign_in'.tr,
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
