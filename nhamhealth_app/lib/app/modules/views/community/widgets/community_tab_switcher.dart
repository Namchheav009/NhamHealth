import 'package:flutter/material.dart';

import '../../../controllers/community/community_controller.dart';
import '../../../../theme/app_colors.dart';

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
  static const _muted = Color(0xFF718078);

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2EBE5)),
    ),
    child: Row(
      children:
          CommunitySection.values.map((section) {
            final isSelected = selected == section;
            return Expanded(
              child: InkWell(
                key: ValueKey('community-tab-${section.name}'),
                onTap: () => onChanged(section),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFFE5F7EB)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[section.index],
                        size: 18,
                        color: isSelected ? AppColors.primaryGreen : _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _labels[section.index],
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF087B3A) : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    ),
  );
}
