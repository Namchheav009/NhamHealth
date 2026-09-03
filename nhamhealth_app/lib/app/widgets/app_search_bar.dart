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
    this.trailing,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showClear;
  final bool useSoftHomeStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.appSearchSurface.withValues(alpha: isDark ? .97 : .94),
        borderRadius: BorderRadius.circular(18),
        border:
            useSoftHomeStyle && !isDark
                ? null
                : Border.all(
                  color: isDark ? colors.outlineVariant : colors.outline,
                ),
        boxShadow:
            useSoftHomeStyle
                ? context.appHomeCardShadow
                : context.appCardShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded, color: colors.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: colors.primary,
              style: TextStyle(color: colors.onSurface, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: hintText.tr,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (showClear)
            IconButton(
              key: const ValueKey('search-clear'),
              tooltip: 'Clear search'.tr,
              onPressed: onClear,
              icon: Icon(
                Icons.close_rounded,
                size: 19,
                color: colors.onSurfaceVariant,
              ),
            )
          else if (trailing == null)
            const SizedBox(width: 48),
          if (trailing case final trailing?)
            Padding(padding: const EdgeInsets.only(right: 4), child: trailing),
        ],
      ),
    );
  }
}
