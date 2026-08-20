import 'package:flutter/material.dart';

import 'social_login_button.dart';

class PlatformGoogleSignInButton extends StatelessWidget {
  const PlatformGoogleSignInButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.onAuthenticated,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final ValueChanged<String> onAuthenticated;

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      label: label,
      loading: loading,
      onPressed: onPressed,
    );
  }
}
