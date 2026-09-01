import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../controllers/splash/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedLogo(),
                const SizedBox(height: 28),
                _buildAnimatedAppName(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: controller.animationController,
        child: Image.asset(
          'assets/icons/logo.png',
          width: 110,
          height: 110,
          fit: BoxFit.contain,
        ),
        builder: (context, child) {
          final bool isSpinning = controller.animationController.value < 0.55;

          if (isSpinning) {
            return Opacity(
              opacity: controller.logoSpinOpacity.value,
              child: Transform.rotate(
                angle: controller.logoRotation.value,
                child: child,
              ),
            );
          }

          return Opacity(
            opacity: controller.logoOpacity.value,
            child: Transform.scale(
              scale: controller.logoScale.value,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedAppName() {
    return AnimatedBuilder(
      animation: controller.textReveal,
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'NHAM ',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryPink,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: 'HEALTH',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryGreen,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: controller.textReveal.value,
            child: child,
          ),
        );
      },
    );
  }
}
