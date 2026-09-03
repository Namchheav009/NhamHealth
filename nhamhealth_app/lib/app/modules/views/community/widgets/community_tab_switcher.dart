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
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isDark
                ? colors.surfaceContainerHigh.withValues(alpha: .92)
                : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(28),
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
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (isDark
                                    ? colors.surfaceContainerHighest
                                    : Colors.white)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : const [],
                      ),
                      child: Text(
                        _labels[section.index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color:
                              isSelected
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                        ),
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
