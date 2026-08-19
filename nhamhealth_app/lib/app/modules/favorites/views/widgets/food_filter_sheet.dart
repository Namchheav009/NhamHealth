import 'package:flutter/material.dart';

class FoodFilterSheet extends StatefulWidget {
  const FoodFilterSheet({
    super.key,
    required this.categories,
    required this.initialCategory,
    required this.onApply,
  });

  final List<String> categories;
  final String initialCategory;
  final ValueChanged<String> onApply;

  @override
  State<FoodFilterSheet> createState() => _FoodFilterSheetState();
}

class _FoodFilterSheetState extends State<FoodFilterSheet> {
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
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
            child: SingleChildScrollView(
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
                      const Expanded(
                        child: Text(
                          'Filter by category',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: selectedCategory == 'All'
                            ? null
                            : () => setState(() => selectedCategory = 'All'),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                    ),
                    itemCount: widget.categories.length,
                    itemBuilder: (_, index) {
                      final category = widget.categories[index];
                      final selected = category == selectedCategory;
                      return ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(category, textAlign: TextAlign.center),
                        ),
                        selected: selected,
                        showCheckmark: false,
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF0AA653)
                              : const Color(0xFFDDE5E0),
                        ),
                        selectedColor: const Color(0xFFDDF7E6),
                        backgroundColor: const Color(0xFFF9FBFA),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFF087A42)
                              : const Color(0xFF555555),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => selectedCategory = category),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(selectedCategory);
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0AA653),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
