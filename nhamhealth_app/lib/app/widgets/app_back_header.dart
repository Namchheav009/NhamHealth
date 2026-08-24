import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Consistent page header for secondary screens.
class AppBackHeader extends StatelessWidget {
  const AppBackHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backButtonKey,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Key? backButtonKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Tooltip(
            message: 'Back'.tr,
            child: Material(
              color: Colors.white.withValues(alpha: 0.82),
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: const Color(0x1A244C35),
              child: InkWell(
                key: backButtonKey,
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
