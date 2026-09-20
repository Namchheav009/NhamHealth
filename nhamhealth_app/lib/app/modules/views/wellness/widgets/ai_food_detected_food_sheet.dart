import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_alert.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../repositories/wellness/food_nutrition_repository.dart';

class AiFoodDetectedFoodSheet extends StatefulWidget {
  const AiFoodDetectedFoodSheet({super.key, required this.controller});

  final AiFoodController controller;

  @override
  State<AiFoodDetectedFoodSheet> createState() =>
      _AiFoodDetectedFoodSheetState();
}

class _AiFoodDetectedFoodSheetState extends State<AiFoodDetectedFoodSheet> {
  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);
  static const greenLightBg = Color(0xFFEAF7EE);

  late final TextEditingController _nameController;
  late final TextEditingController _customCuisineController;
  late bool _isDrink;
  late String _selectedCuisine;

  static const List<String> _commonFoodCuisines = [
    'Khmer',
    'Asian',
    'Western',
    'Italian',
    'Healthy',
    'Dessert',
    'Street Food',
  ];

  static const List<String> _commonDrinkCategories = [
    'Beverage',
    'Coffee',
    'Tea',
    'Juice',
    'Smoothie',
    'Water',
    'Soft Drink',
    'Healthy',
  ];

  late List<String> _cuisines;
  bool _isLoadingCategories = false;

  Timer? _debounceTimer;
  List<FoodSuggestion> _suggestions = const [];
  bool _isSearching = false;
  List<String> _candidates = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.detectedFoodName,
    );
    _customCuisineController = TextEditingController();

    _isDrink = widget.controller.inputKind.value == AiFoodInputKind.drink;

    // Detect initial cuisine choice
    final currentCuisine =
        widget.controller.customCuisine.value ??
        (widget.controller.nutrition.value?.cuisine != 'Unknown' &&
                widget.controller.nutrition.value?.cuisine.isNotEmpty == true
            ? widget.controller.nutrition.value!.cuisine
            : (_isDrink ? 'Beverage' : 'Healthy'));

    final defaultList = _isDrink ? _commonDrinkCategories : _commonFoodCuisines;
    _cuisines = List<String>.from(defaultList);
    if (!_cuisines.contains(currentCuisine) && currentCuisine != 'Other') {
      _cuisines.insert(0, currentCuisine);
    }

    if (_cuisines.contains(currentCuisine)) {
      _selectedCuisine = currentCuisine;
    } else {
      _selectedCuisine = 'Other';
      _customCuisineController.text = currentCuisine;
    }

    // Extract AI candidates if present
    final detCandidates = widget.controller.detection.value?.candidates ?? [];
    if (detCandidates.isNotEmpty) {
      _candidates = detCandidates;
    } else {
      final nutCandidates =
          widget.controller.nutrition.value?.candidates
              .map((c) => c.name)
              .toList() ??
          [];
      if (nutCandidates.isNotEmpty) {
        _candidates = nutCandidates;
      }
    }

    _nameController.addListener(_onNameChanged);
    _loadDynamicCategories();
  }

  Future<void> _loadDynamicCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final apiCategories = await widget.controller.loadMealCategories();
      if (!mounted) return;
      final merged = <String>{};
      // Keep selected cuisine and detected categories first
      if (_selectedCuisine != 'Other' && _selectedCuisine.isNotEmpty) {
        merged.add(_selectedCuisine);
      }
      if (_isDrink) {
        for (final cat in apiCategories) {
          final l = cat.toLowerCase();
          if (l.contains('drink') ||
              l.contains('beverage') ||
              l.contains('juice') ||
              l.contains('coffee') ||
              l.contains('tea') ||
              l.contains('smoothie') ||
              l.contains('water')) {
            merged.add(cat);
          }
        }
        merged.addAll(_commonDrinkCategories);
      } else {
        for (final cat in apiCategories) {
          final l = cat.toLowerCase();
          if (!l.contains('drink') && !l.contains('beverage')) {
            merged.add(cat);
          }
        }
        merged.addAll(_commonFoodCuisines);
      }

      setState(() {
        _cuisines = merged.toList();
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _onNameChanged() {
    final query = _nameController.text.trim();
    _debounceTimer?.cancel();
    if (query.length < 2) {
      if (_suggestions.isNotEmpty || _isSearching) {
        setState(() {
          _suggestions = const [];
          _isSearching = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await widget.controller.searchFoodSuggestions(query);
        if (!mounted) return;
        final filtered =
            results.where((s) => _isDrink ? s.isDrink : !s.isDrink).toList();
        setState(() {
          _suggestions = filtered;
          _isSearching = false;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = const [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _selectSuggestion(FoodSuggestion suggestion) {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.text = suggestion.name;
    _nameController.addListener(_onNameChanged);

    setState(() {
      _suggestions = const [];
      _isSearching = false;
      if (suggestion.category != null && suggestion.category!.isNotEmpty) {
        final cat = suggestion.category!;
        if (!_cuisines.contains(cat)) {
          _cuisines.insert(0, cat);
        }
        _selectedCuisine = cat;
      }
    });
  }

  void _selectCandidate(String candidateName) {
    _nameController.text = candidateName;
    setState(() {
      _suggestions = const [];
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _customCuisineController.dispose();
    super.dispose();
  }

  void _onSave() {
    final foodName = _nameController.text.trim();
    if (foodName.isEmpty) {
      AppAlert.toast(
        message:
            _isDrink
                ? 'Please enter a drink name'
                : 'Please enter a food name',
      );
      return;
    }

    final cuisine =
        _selectedCuisine == 'Other'
            ? (_customCuisineController.text.trim().isNotEmpty
                ? _customCuisineController.text.trim()
                : (_isDrink ? 'Beverage' : 'Healthy'))
            : _selectedCuisine;

    widget.controller.updateDetectedFood(
      name: foodName,
      cuisine: cuisine,
      isDrink: _isDrink,
    );

    Navigator.of(context).pop(true);
    AppAlert.toast(
      message:
          _isDrink
              ? 'Detected drink updated to $foodName'
              : 'Detected food updated to $foodName',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 620,
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildNameField(context),
                  const SizedBox(height: 18),
                  _buildTypeSelector(context),
                  const SizedBox(height: 18),
                  _buildCuisineSelector(context),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title =
        _isDrink
            ? 'wellness.edit_detected_drink'.trOrSelf
            : 'wellness.edit_detected_food'.trOrSelf;
    final subtitle =
        _isDrink
            ? 'Adjust drink name or category if AI detection needs correction.'
            : 'Adjust food name or category if AI detection needs correction.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.appIsDark ? const Color(0xFF143021) : greenLightBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            _isDrink ? Icons.local_drink_rounded : Icons.lunch_dining_rounded,
            color: green,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: context.appMutedText),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          color: context.appMutedText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    final isDark = context.appIsDark;
    final label =
        _isDrink
            ? 'wellness.drink_name'.trOrSelf
            : 'wellness.food_name'.trOrSelf;
    final hint =
        _isDrink
            ? 'e.g., Iced Latte, Fresh Orange Juice, Green Tea'
            : 'e.g., Chicken Rice, Salad Bowl, Fried Noodles';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            if (_isSearching)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(green),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.appText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.appMutedText, fontSize: 14),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: green),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () {
                _nameController.clear();
                setState(() => _suggestions = const []);
              },
            ),
            filled: true,
            fillColor: isDark ? context.appSurfaceLow : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: green, width: 1.8),
            ),
          ),
        ),
        // Live search suggestions dropdown
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? context.appSurfaceLow : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: green.withValues(alpha: .35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .3 : .08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 14, color: green),
                      const SizedBox(width: 6),
                      Text(
                        _isDrink ? 'Matching Verified Drinks' : 'Matching Verified Foods',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.appMutedText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8),
                ..._suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            suggestion.isDrink
                                ? Icons.local_drink_rounded
                                : Icons.restaurant_rounded,
                            size: 16,
                            color: green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.appText,
                                  ),
                                ),
                                if (suggestion.category != null ||
                                    suggestion.calories != null)
                                  Text(
                                    [
                                      if (suggestion.category != null)
                                        suggestion.category!,
                                      if (suggestion.calories != null)
                                        '${suggestion.calories!.round()} kcal',
                                    ].join(' • '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.appMutedText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 14,
                            color: greenDark,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        // AI Candidates quick selection chips
        if (_candidates.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: green),
              const SizedBox(width: 5),
              Text(
                'AI Suggestions:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.appMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                _candidates.take(4).map((cand) {
                  return ActionChip(
                    label: Text(cand),
                    onPressed: () => _selectCandidate(cand),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: greenDark,
                    ),
                    backgroundColor:
                        isDark ? const Color(0xFF143021) : greenLightBg,
                    side: const BorderSide(color: green, width: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!_isDrink)
              Expanded(
                child: _buildTypeOption(
                  label: 'Food / Meal',
                  icon: Icons.restaurant_rounded,
                  selected: true,
                  onTap: () {},
                ),
              ),
            if (_isDrink)
              Expanded(
                child: _buildTypeOption(
                  label: 'Drink / Beverage',
                  icon: Icons.local_drink_rounded,
                  selected: true,
                  onTap: () {},
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = context.appIsDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? (isDark ? const Color(0xFF143021) : greenLightBg)
                    : (isDark
                        ? context.appSurfaceLow
                        : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? green : context.appBorder,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? green : context.appMutedText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? greenDark : context.appText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuisineSelector(BuildContext context) {
    final isDark = context.appIsDark;
    final categoryLabel = _isDrink ? 'Drink Category' : 'Cuisine / Category';
    final customHint =
        _isDrink
            ? 'Enter custom category (e.g., Boba, Herbal Tea)'
            : 'Enter custom category (e.g., Mexican, Bakery)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
            if (_isLoadingCategories)
              Row(
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(green),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Syncing...',
                    style: TextStyle(fontSize: 11, color: context.appMutedText),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._cuisines.map((c) {
              final isSel = _selectedCuisine == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSel,
                onSelected: (_) {
                  setState(() => _selectedCuisine = c);
                },
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSel
                          ? (isDark ? Colors.white : greenDark)
                          : context.appText,
                ),
                selectedColor:
                    isDark ? const Color(0xFF1B4D31) : const Color(0xFFD1FAE5),
                backgroundColor:
                    isDark ? context.appSurfaceLow : const Color(0xFFF3F4F6),
                side: BorderSide(color: isSel ? green : context.appBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
            ChoiceChip(
              label: const Text('Other'),
              selected: _selectedCuisine == 'Other',
              onSelected: (_) {
                setState(() => _selectedCuisine = 'Other');
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight:
                    _selectedCuisine == 'Other'
                        ? FontWeight.w700
                        : FontWeight.w500,
                color:
                    _selectedCuisine == 'Other'
                        ? (isDark ? Colors.white : greenDark)
                        : context.appText,
              ),
              selectedColor:
                  isDark ? const Color(0xFF1B4D31) : const Color(0xFFD1FAE5),
              backgroundColor:
                  isDark ? context.appSurfaceLow : const Color(0xFFF3F4F6),
              side: BorderSide(
                color: _selectedCuisine == 'Other' ? green : context.appBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        if (_selectedCuisine == 'Other') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customCuisineController,
            style: TextStyle(fontSize: 14, color: context.appText),
            decoration: InputDecoration(
              hintText: customHint,
              hintStyle: TextStyle(color: context.appMutedText, fontSize: 13),
              filled: true,
              fillColor:
                  isDark ? context.appSurfaceLow : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appMutedText,
                side: BorderSide(color: context.appBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('common.cancel'.trOrSelf),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
