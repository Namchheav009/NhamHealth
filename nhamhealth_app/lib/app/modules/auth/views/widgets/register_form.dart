import 'package:flutter/material.dart';

import 'auth_tab_switcher.dart';
import 'password_field.dart';
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
    required this.onLogin,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final VoidCallback onRegister;
  final VoidCallback onGoogle;
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
          const SizedBox(height: 15),
          const Text(
            'Create your account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF005B27),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: fullNameController,
            hintText: 'Full name',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: emailController,
            hintText: 'Email address',
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
          const SizedBox(height: 15),
          AuthPrimaryButton(
            label: 'Create account',
            loading: loading,
            onPressed: onRegister,
          ),
          const SizedBox(height: 11),
          SocialLoginButton(
            label: 'Continue with Google',
            loading: loading,
            onPressed: onGoogle,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(child: Text('Already have an account?')),
              TextButton(
                onPressed: loading ? null : onLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFFFF9800),
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
