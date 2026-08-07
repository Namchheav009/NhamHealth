import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../services/google_auth_service.dart';

class PlatformGoogleSignInButton extends StatefulWidget {
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
  State<PlatformGoogleSignInButton> createState() =>
      _PlatformGoogleSignInButtonState();
}

class _PlatformGoogleSignInButtonState
    extends State<PlatformGoogleSignInButton> {
  StreamSubscription<String>? _authenticationSubscription;
  Object? _initializationError;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final service =
          Get.isRegistered<GoogleAuthService>()
              ? Get.find<GoogleAuthService>()
              : GoogleAuthService();
      await service.initialize();
      if (!mounted) return;

      _authenticationSubscription = service.authenticationTokens.listen(
        _handleIdToken,
        onError: _showError,
      );
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _initializationError = error);
    }
  }

  void _handleIdToken(String idToken) {
    if (!mounted) return;
    widget.onAuthenticated(idToken);
  }

  void _showError(Object error) {
    if (!mounted) return;
    Get.snackbar(
      'Google sign in failed',
      error.toString(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFB3261E),
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    unawaited(_authenticationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError case final error?) {
      return Tooltip(
        message: error.toString(),
        child: const SizedBox(
          height: 48,
          child: Center(child: Text('Google sign in is unavailable')),
        ),
      );
    }

    if (!_ready || widget.loading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(1.0, 400.0).toDouble();
        return SizedBox(
          height: 48,
          child: Center(
            child: web.renderButton(
              configuration: web.GSIButtonConfiguration(
                type: web.GSIButtonType.standard,
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                text: web.GSIButtonText.continueWith,
                shape: web.GSIButtonShape.pill,
                logoAlignment: web.GSIButtonLogoAlignment.left,
                minimumWidth: width,
              ),
            ),
          ),
        );
      },
    );
  }
}
