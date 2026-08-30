import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';

class MoodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final content = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder:
                      (child, animation) => ScaleTransition(
                        scale: animation,
                        child: RotationTransition(
                          turns: Tween<double>(
                            begin: -0.04,
                            end: 0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child: Center(
                    key: ValueKey('$emoji-$selected'),
                    child:
                        emoji.isEmpty
                            ? const Icon(
                              Icons.mood_rounded,
                              color: Color(0xFFFFB02E),
                              size: 28,
                            )
                            : Text(
                              emoji,
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(fontSize: 28, height: 1),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.tr,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.5,
                      color:
                          selected
                              ? context.appColorScheme.primary
                              : context.appColorScheme.secondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      decoration: BoxDecoration(
        gradient:
            selected
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [context.appSoftGreen, context.appSoftPink],
                )
                : null,
        color: selected ? null : context.appElevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border:
            isDark
                ? Border.all(
                  color:
                      selected
                          ? context.appColorScheme.primary
                          : context.appBorder,
                  width: selected ? 1.6 : 1,
                )
                : null,
        boxShadow:
            !isDark
                ? selected
                    ? [
                      BoxShadow(
                        color: context.appColorScheme.primary.withValues(
                          alpha: 0.13,
                        ),
                        blurRadius: 11,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : context.appHomeTileShadow
                : selected
                ? [
                  BoxShadow(
                    color: context.appColorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                : context.appTileShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(12),
            shadows: isDark ? context.appInnerShadow : const [],
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '@mood mood'.trParams({'mood': label.tr}),
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: card,
      ),
    );
  }
}
