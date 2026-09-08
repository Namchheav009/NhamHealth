import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import 'auth_tab_switcher.dart';
import 'password_field.dart';
import 'platform_google_sign_in_button.dart';
import 'social_login_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.identifierError,
    required this.passwordError,
    required this.submitError,
    required this.credentialsInvalid,
    required this.onLogin,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onGoogle,
    required this.onGoogleAuthenticated,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final String? identifierError;
  final String? passwordError;
  final String? submitError;
  final bool credentialsInvalid;
  final VoidCallback onLogin;
  final ValueChanged<String> onIdentifierChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onGoogle;
  final ValueChanged<String> onGoogleAuthenticated;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTabSwitcher(
            selectedIndex: 0,
            onLogin: () {},
            onRegister: onRegister,
          ),
          const SizedBox(height: 22),
          const SizedBox(height: 5),
          Text(
            'Sign in to continue your healthy journey.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMutedText, fontSize: 12),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            key: const ValueKey<String>('login-identifier-field'),
            controller: emailController,
            hintText: 'Email or Phone Number'.tr,
            prefixIcon: Icons.account_circle_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
              AutofillHints.telephoneNumber,
            ],
            hasError: credentialsInvalid,
            errorText: identifierError,
            onChanged: onIdentifierChanged,
          ),
          const SizedBox(height: 10),
          PasswordField(
            key: const ValueKey<String>('login-password-field'),
            controller: passwordController,
            hintText: 'Password',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            hasError: credentialsInvalid,
            errorText: passwordError,
            onChanged: onPasswordChanged,
            onSubmitted: (_) => onLogin(),
          ),
          AuthInlineError(message: submitError),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : onForgotPassword,
              child: Text(
                'Forgot password?'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          AuthPrimaryButton(
            label: 'Sign In',
            loading: loading,
            onPressed: onLogin,
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
                  "Don't have an account?".tr,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: loading ? null : onRegister,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign Up'.tr,
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
