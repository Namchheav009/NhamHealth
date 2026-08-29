import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared back control used by every full-page header.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed, this.buttonKey})
    : inAppBar = false;

  const AppBackButton.appBar({
    super.key,
    required this.onPressed,
    this.buttonKey,
  }) : inAppBar = true;

  static const double visualSize = 44;
  static const double layoutSize = 52;
  static const double iconSize = 24;
  static const double headerGap = 8;
  static const double appBarLeadingWidth = 68;
  static const double appBarToolbarHeight = 64;
  static const EdgeInsets outerMargin = EdgeInsets.all(4);
  static const EdgeInsets contentPadding = EdgeInsets.all(10);
  static const EdgeInsets appBarLeadingPadding = EdgeInsets.only(left: 16);

  final VoidCallback? onPressed;
  final Key? buttonKey;
  final bool inAppBar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final button = SizedBox.square(
      dimension: layoutSize,
      child: Padding(
        padding: outerMargin,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: 'Back'.tr,
          child: Tooltip(
            message: 'Back'.tr,
            child: Material(
              color: colors.surface.withValues(alpha: enabled ? 0.9 : 0.55),
              shape: const CircleBorder(),
              elevation: enabled ? 1 : 0,
              shadowColor: Colors.black.withValues(alpha: 0.16),
              child: InkWell(
                key: buttonKey,
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: contentPadding,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color:
                        enabled
                            ? colors.primary
                            : colors.onSurface.withValues(alpha: 0.35),
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!inAppBar) return button;
    return SizedBox(
      width: appBarLeadingWidth,
      height: layoutSize,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: appBarLeadingPadding, child: button),
      ),
    );
  }
}

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
      height: AppBackButton.layoutSize,
      child: Row(
        children: [
          AppBackButton(onPressed: onBack, buttonKey: backButtonKey),
          const SizedBox(width: AppBackButton.headerGap),
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
