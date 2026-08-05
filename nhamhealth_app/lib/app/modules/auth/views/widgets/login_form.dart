import 'package:flutter/material.dart';

import 'auth_tab_switcher.dart';
import 'password_field.dart';
import 'social_login_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.onLogin,
    required this.onGoogle,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final VoidCallback onLogin;
  final VoidCallback onGoogle;
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
          const SizedBox(height: 17),
          const Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF005B27),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: emailController,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: passwordController,
            hintText: 'Password',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onLogin(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : onForgotPassword,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: Color(0xFF005B27),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AuthPrimaryButton(
            label: 'Login',
            loading: loading,
            onPressed: onLogin,
          ),
          const SizedBox(height: 12),
          SocialLoginButton(
            label: 'Continue with Google',
            loading: loading,
            onPressed: onGoogle,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(child: Text("Don't have an account?")),
              TextButton(
                onPressed: loading ? null : onRegister,
                child: const Text(
                  'Register',
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
