import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/splash/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.transparent,
              body: AppBackground(
                lightDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundMint,
                      AppColors.backgroundCream,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxHeight < 650;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildContent(
                            context,
                            isSmallScreen: isSmallScreen,
                          ),

                          _buildLoadingIndicator(context),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isSmallScreen}) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedLogo(size: isSmallScreen ? 108 : 128),

              SizedBox(height: isSmallScreen ? 18 : 24),

              _buildAnimatedAppName(),

              const SizedBox(height: 10),

              _buildSubtitle(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo({required double size}) {
    return AnimatedBuilder(
      animation: controller.animationController,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              blurRadius: 32,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Image.asset(
          'assets/icons/logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
      builder: (context, child) {
        final progress = (controller.animationController.value / 0.55).clamp(
          0.0,
          1.0,
        );

        final curvedValue = Curves.easeOutBack.transform(progress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - progress)),
            child: Transform.scale(
              scale: 0.82 + (0.18 * curvedValue),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAppName() {
    return AnimatedBuilder(
      animation: controller.textReveal,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'NHAM ',
                style: TextStyle(
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryPink,
                  letterSpacing: 0.7,
                ),
              ),
              TextSpan(
                text: 'HEALTH',
                style: TextStyle(
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, child) {
        final progress = controller.textReveal.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - progress)),
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                widthFactor: progress,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (_, _) {
        final progress = ((controller.animationController.value - 0.62) / 0.38)
            .clamp(0.0, 1.0);

        final curvedValue = Curves.easeOutCubic.transform(progress);

        return Opacity(
          opacity: curvedValue,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - curvedValue)),
            child: Text(
              'Healthy choices, made simpler.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 36,
      child: AnimatedBuilder(
        animation: controller.animationController,
        builder: (_, _) {
          final progress = ((controller.animationController.value - 0.75) /
                  0.25)
              .clamp(0.0, 1.0);

          return Opacity(
            opacity: progress,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    strokeCap: StrokeCap.round,
                    color: context.appColorScheme.primary,
                    backgroundColor: context.appColorScheme.outlineVariant
                        .withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Getting things ready...'.tr,
                  style: TextStyle(
                    color: context.appMutedText.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
