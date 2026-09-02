import 'package:flutter/material.dart';

import '../../../controllers/community/community_controller.dart';

class CommunityTabSwitcher extends StatelessWidget {
  const CommunityTabSwitcher({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CommunitySection selected;
  final ValueChanged<CommunitySection> onChanged;

  static const _labels = ['Feed', 'People'];
  static const _icons = [
    Icons.dynamic_feed_outlined,
    Icons.people_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.surface,
            colors.surfaceContainer,
            Color.alphaBlend(
              colors.primary.withValues(alpha: isDark ? .12 : .06),
              colors.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .2 : .08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children:
            CommunitySection.values.map((section) {
              final isSelected = selected == section;
              return Expanded(
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: '${_labels[section.index]} tab',
                  child: InkWell(
                    key: ValueKey('community-tab-${section.name}'),
                    onTap: () => onChanged(section),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? colors.primaryContainer.withValues(alpha: .42)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _icons[section.index],
                            size: 16,
                            color:
                                isSelected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _labels[section.index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                              color:
                                  isSelected
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
