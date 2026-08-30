import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClear = false,
    this.useSoftHomeStyle = false,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showClear;
  final bool useSoftHomeStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border:
            useSoftHomeStyle && !isDark
                ? null
                : Border.all(color: colors.outline),
        boxShadow:
            useSoftHomeStyle
                ? context.appHomeCardShadow
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: colors.onSurfaceVariant, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: colors.primary,
              style: TextStyle(color: colors.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText.tr,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child:
                showClear
                    ? IconButton(
                      key: const ValueKey('search-clear'),
                      tooltip: 'Clear search'.tr,
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: colors.onSurfaceVariant,
                      ),
                    )
                    : const SizedBox(width: 48),
          ),
        ],
      ),
    );
  }
}
