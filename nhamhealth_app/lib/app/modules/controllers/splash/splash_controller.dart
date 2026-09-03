import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_security_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/pin_setup_prompt.dart';
import '../../../widgets/privacy_auth_dialog.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../views/profile/security_view.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;

  /// Logo animations
  late final Animation<double> logoScale;
  late final Animation<double> logoOpacity;
  late final Animation<Offset> logoSlide;

  /// Text animations
  late final Animation<double> textReveal;
  late final Animation<double> subtitleOpacity;
  late final Animation<Offset> subtitleSlide;

  /// Loading animation
  late final Animation<double> loaderOpacity;

  bool _hasNavigated = false;

  late final Future<AuthenticatedUser?> _sessionFuture;

  @override
  void onInit() {
    super.onInit();

    // Start restoring the session immediately.
    // It runs while the splash animation is playing.
    _sessionFuture = _restoreSessionSafely();

    _initializeAnimationController();
    _initializeAnimations();

    animationController.addStatusListener(_handleAnimationStatus);
    animationController.forward();
  }

  void _initializeAnimationController() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  void _initializeAnimations() {
    // Logo fade in.
    logoOpacity = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.00, 0.32, curve: Curves.easeOut),
    );

    // Logo slightly grows into position.
    logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.00, 0.42, curve: Curves.easeOutBack),
      ),
    );

    // Logo moves upward gently.
    logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.00, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    // NHAM HEALTH reveal.
    textReveal = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.30, 0.67, curve: Curves.easeOutCubic),
    );

    // Subtitle fade.
    subtitleOpacity = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.52, 0.82, curve: Curves.easeOut),
    );

    // Subtitle moves slightly upward.
    subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.52, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Loading indicator appears last.
    loaderOpacity = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.68, 1.00, curve: Curves.easeOut),
    );
  }

  Future<AuthenticatedUser?> _restoreSessionSafely() async {
    try {
      return await Get.find<AuthService>().restoreSession();
    } catch (error, stackTrace) {
      debugPrint('SplashController: session restoration failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    if (_hasNavigated || isClosed) {
      return;
    }

    _hasNavigated = true;

    unawaited(_finishStartup());
  }

  Future<void> _finishStartup() async {
    final user = await _sessionFuture;

    if (isClosed) return;

    if (user == null) {
      _goToOnboarding();
      return;
    }

    await _handleAuthenticatedUser(user);
  }

  Future<void> _handleAuthenticatedUser(AuthenticatedUser user) async {
    final security = Get.find<AppSecurityService>();

    security.syncPinState(user.hasPin);

    if (!user.hasPin) {
      await _handleMissingPin(user);
      return;
    }

    await _unlockApplication(user);
  }

  Future<void> _handleMissingPin(AuthenticatedUser user) async {
    final context = Get.context;

    if (context != null && !isClosed) {
      await showPinSetupPrompt(context);
    }

    if (isClosed) return;

    Get.offAll<void>(
      () => SecurityView(
        promptCreatePin: true,
        requirePinCreation: true,
        onPinCreated: () {
          if (isClosed) return;

          Get.offAllNamed(AppRoutes.home, arguments: user);
        },
      ),
    );
  }

  Future<void> _unlockApplication(AuthenticatedUser user) async {
    if (isClosed) return;

    final unlocked = await PrivacyAuth.require(
      reason: 'Enter your PIN to open NhamHealth.',
      allowCancel: false,
    );

    if (!unlocked || isClosed) {
      return;
    }

    Get.offAllNamed(AppRoutes.home, arguments: user);
  }

  void _goToOnboarding() {
    if (isClosed) return;

    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  void onClose() {
    animationController.removeStatusListener(_handleAnimationStatus);

    animationController.dispose();

    super.onClose();
  }
}
