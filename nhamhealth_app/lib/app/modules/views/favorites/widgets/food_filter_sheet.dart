import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodFilterSheet extends StatefulWidget {
  const FoodFilterSheet({
    super.key,
    required this.categories,
    required this.initialCategories,
    required this.onApply,
  });

  final List<String> categories;
  final Set<String> initialCategories;
  final ValueChanged<Set<String>> onApply;

  @override
  State<FoodFilterSheet> createState() => _FoodFilterSheetState();
}

class _FoodFilterSheetState extends State<FoodFilterSheet> {
  late Set<String> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories =
        widget.initialCategories
            .where(widget.categories.contains)
            .where((category) => category != 'All')
            .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenHeight * .72,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DEDB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF8EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_alt_outlined,
                    size: 21,
                    color: Color(0xFF0AA653),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filter by category'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      selectedCategories.isEmpty
                          ? null
                          : () => setState(selectedCategories.clear),
                  child: Text('Reset'.tr),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chipWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final category in widget.categories)
                          SizedBox(
                            width: chipWidth,
                            child: _CategoryChip(
                              label: category,
                              selected:
                                  category == 'All'
                                      ? selectedCategories.isEmpty
                                      : selectedCategories.contains(category),
                              onTap:
                                  () => setState(() {
                                    if (category == 'All') {
                                      selectedCategories.clear();
                                    } else if (!selectedCategories.add(
                                      category,
                                    )) {
                                      selectedCategories.remove(category);
                                    }
                                  }),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(Set<String>.of(selectedCategories));
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0AA653),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Apply Filter'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF0AA653);
    return Semantics(
      button: true,
      selected: selected,
      label: '@category category'.trParams({'category': label.tr}),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFFE1F7E8) : const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : const Color(0xFFDDE5E0),
                width: selected ? 1.5 : 1,
              ),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: accent.withValues(alpha: .14),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child:
                      selected
                          ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0AA653),
                            size: 18,
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected
                              ? const Color(0xFF087A42)
                              : const Color(0xFF555555),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
