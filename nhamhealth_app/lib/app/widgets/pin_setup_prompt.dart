import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

Future<void> showPinSetupPrompt(BuildContext context) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PIN setup required'.tr,
      barrierColor: AppColors.darkGreen.withValues(alpha: .24),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder:
          (context, animation, secondaryAnimation) => const _PinSetupPrompt(),
      transitionBuilder:
          (context, animation, secondaryAnimation, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          ),
    );

class _PinSetupPrompt extends StatelessWidget {
  const _PinSetupPrompt();

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: context.appElevatedSurface.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: context.appStrongBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: .2),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _securityIcon(),
                  const SizedBox(height: 20),
                  Text(
                    'Protect your health data'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Create a 6-digit PIN before continuing to NhamHealth.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _BenefitRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Private by default',
                    subtitle: 'Protects AI Food and personal health details',
                  ),
                  const SizedBox(height: 14),
                  const _BenefitRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Fast unlock',
                    subtitle: 'Enable fingerprint or Face ID afterward',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('create-secure-pin-button'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.pin_rounded, size: 20),
                    label: Text('Create secure PIN'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: context.appMutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your PIN is securely hashed'.tr,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _securityIcon() => Container(
    width: 82,
    height: 82,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00BE63), AppColors.darkGreen],
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryGreen.withValues(alpha: .28),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.appSoftGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 23),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle.tr,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
