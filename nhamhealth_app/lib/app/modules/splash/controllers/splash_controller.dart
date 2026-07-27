import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;

  late final Animation<double> logoRotation;
  late final Animation<double> logoSpinOpacity;
  late final Animation<double> logoScale;
  late final Animation<double> logoOpacity;
  late final Animation<double> textReveal;

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _initializeAnimations();

    animationController.forward();
  }

  void _initializeAnimations() {
    // Stage 1: logo rotation
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

    // Stage 2: logo bounce
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

    // Stage 3: text reveal
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

  void replayAnimation() {
    animationController
      ..reset()
      ..forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}