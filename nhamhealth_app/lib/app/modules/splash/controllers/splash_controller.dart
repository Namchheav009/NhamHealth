import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/app_security_service.dart';
import '../../../widgets/privacy_auth_dialog.dart';
import '../../profile/views/security_view.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;

  late final Animation<double> logoRotation;
  late final Animation<double> logoSpinOpacity;
  late final Animation<double> logoScale;
  late final Animation<double> logoOpacity;
  late final Animation<double> textReveal;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _initializeAnimations();

    animationController.addStatusListener(_handleAnimationStatus);
    animationController.forward();
  }

  void _initializeAnimations() {
    logoRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeInOut,
        ),
      ),
    );

    logoSpinOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.0,
          0.20,
          curve: Curves.easeIn,
        ),
      ),
    );

    logoScale = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.45,
          0.75,
          curve: Curves.elasticOut,
        ),
      ),
    );

    logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.45,
          0.65,
          curve: Curves.easeIn,
        ),
      ),
    );

    textReveal = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.65,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    _navigationTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!isClosed) {
          _finishStartup();
        }
      },
    );
  }

  Future<void> _finishStartup() async {
    final user = await Get.find<AuthService>().restoreSession();
    if (isClosed) return;

    if (user != null) {
      final security = Get.find<AppSecurityService>();
      security.syncPinState(user.hasPin);
      if (!user.hasPin) {
        Get.offAll<void>(
          () => SecurityView(
            promptCreatePin: true,
            requirePinCreation: true,
            onPinCreated:
                () => Get.offAllNamed(AppRoutes.home, arguments: user),
          ),
        );
        return;
      }
      final unlocked = await PrivacyAuth.require(
        reason: 'Enter your PIN to open NhamHealth.',
        allowCancel: false,
      );
      if (unlocked && !isClosed) {
        Get.offAllNamed(AppRoutes.home, arguments: user);
      }
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();

    animationController.removeStatusListener(
      _handleAnimationStatus,
    );

    animationController.dispose();

    super.onClose();
  }
}
