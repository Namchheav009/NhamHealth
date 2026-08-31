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
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFBFEFC), Color(0xFFF2F9F4)],
      ),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFD8E9DE)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14173525),
          blurRadius: 14,
          offset: Offset(0, 5),
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
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF20BD63), Color(0xFF078A42)],
                              )
                              : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow:
                          isSelected
                              ? const [
                                BoxShadow(
                                  color: Color(0x3D078A42),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[section.index],
                          size: 17,
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF597063),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _labels[section.index],
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF53695C),
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
