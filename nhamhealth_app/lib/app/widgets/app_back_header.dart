import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Consistent page header for secondary screens.
class AppBackHeader extends StatelessWidget {
  const AppBackHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.backButtonKey,
    this.titleWidget,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Key? backButtonKey;
  final Widget? titleWidget;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Tooltip(
            message: 'Back'.tr,
            child: Material(
              color: colors.surface.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.16),
              child: InkWell(
                key: backButtonKey,
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                titleWidget ??
                Text(
                  title.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
