import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class AppSearchBar extends StatefulWidget {
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
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 54,
      decoration: BoxDecoration(
        color: context.appSearchSurface.withValues(alpha: isDark ? .97 : .94),
        borderRadius: BorderRadius.circular(18),
        border:
            widget.useSoftHomeStyle && !isDark && !focused
                ? null
                : Border.all(
                  color:
                      focused
                          ? colors.primary
                          : isDark
                          ? colors.outlineVariant
                          : colors.outline,
                  width: focused ? 1.5 : 1,
                ),
        boxShadow:
            widget.useSoftHomeStyle
                ? context.appHomeCardShadow
                : focused
                ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
                : context.appTileShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(focused),
              color: focused ? colors.primary : colors.onSurfaceVariant,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: colors.primary,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText.tr,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (widget.showClear)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton.filledTonal(
                key: const ValueKey('search-clear'),
                tooltip: 'Clear search'.tr,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else if (widget.trailing == null)
            const SizedBox(width: 16),
          if (widget.trailing case final trailing?) ...[
            Container(
              width: 1,
              height: 26,
              color: colors.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }
}
