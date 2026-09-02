import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../controllers/meals/ingredient_controller.dart';
import '../../models/meals/meal_model.dart';

class IngredientView extends GetView<IngredientController> {
  const IngredientView({super.key});

  static const Color green = Color(0xFF00A846);
  static const Color descriptionGreen = Color(0xFF79C991);

  @override
  Widget build(BuildContext context) {
    final groups = _IngredientGroups.from(controller.ingredients);
    return Scaffold(
      backgroundColor: context.appBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: IconButton(
            onPressed: controller.goBack,
            tooltip: 'Back'.tr,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 29,
              color: Color(0xFF08783D),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'Ingredient'.tr,
          style: TextStyle(
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w700,
            color: context.appIsDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Stack(
        children: [
          const _IngredientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth * .075).clamp(20.0, 34.0);
                final width = (constraints.maxWidth - side * 2).clamp(
                  0.0,
                  370.0,
                );
                final scale = (width / 330).clamp(.88, 1.08);
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(side, 76 * scale, side, 40),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IngredientSummary(
                            count: groups.main.length,
                            scale: scale,
                          ),
                          SizedBox(height: 20 * scale),
                          if (groups.main.isNotEmpty)
                            _IngredientTable(items: groups.main, scale: scale),
                          if (groups.seasonings.isNotEmpty) ...[
                            SizedBox(height: 25 * scale),
                            Padding(
                              padding: EdgeInsets.only(left: 10 * scale),
                              child: Text(
                                'Seasoning & Spices'.tr,
                                style: TextStyle(
                                  color: green,
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(height: 15 * scale),
                            _IngredientTable(
                              items: groups.seasonings,
                              scale: scale,
                            ),
                          ],
                          if (controller.ingredients.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 48 * scale,
                              ),
                              child: Center(
                                child: Text(
                                  'No ingredients available'.tr,
                                  style: TextStyle(
                                    color: descriptionGreen,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientSummary extends StatelessWidget {
  const _IngredientSummary({required this.count, required this.scale});
  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    width: 254 * scale,
    height: 52 * scale,
    padding: EdgeInsets.symmetric(horizontal: 21 * scale),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F2D5),
      borderRadius: BorderRadius.circular(28 * scale),
    ),
    child: Row(
      children: [
        Icon(
          Icons.eco_rounded,
          color: const Color(0xFF35BF16),
          size: 31 * scale,
        ),
        SizedBox(width: 17 * scale),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredients'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: IngredientView.green,
                  fontSize: 16 * scale,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                '$count healthy ingredients'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: IngredientView.descriptionGreen,
                  fontSize: 9.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IngredientTable extends StatelessWidget {
  const _IngredientTable({required this.items, required this.scale});
  final List<MealIngredientModel> items;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      18 * scale,
      14 * scale,
      17 * scale,
      14 * scale,
    ),
    decoration: BoxDecoration(
      color:
          context.appIsDark
              ? Colors.white.withValues(alpha: .08)
              : Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(17 * scale),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18 * scale,
            child: _Timeline(count: items.length, scale: scale),
          ),
          SizedBox(width: 7 * scale),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items) _rowText(_name(item), context),
              ],
            ),
          ),
          Container(
            width: 1.5,
            margin: EdgeInsets.symmetric(horizontal: 12 * scale),
            color: const Color(0xFF8CE4B4),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items) _rowText(_amount(item), context),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _rowText(String value, BuildContext context) => SizedBox(
    height: 24 * scale,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.appIsDark ? Colors.white70 : const Color(0xFF8A8A8A),
          fontSize: 13.5 * scale,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  String _name(MealIngredientModel item) =>
      item.preparationNote.isEmpty
          ? item.name.tr
          : '${item.name.tr}, ${item.preparationNote.tr}';
  String _amount(MealIngredientModel item) {
    if (item.quantity == null) {
      return item.description.isEmpty ? '—' : item.description.tr;
    }
    final quantity = item.quantity!;
    final value =
        quantity.toDouble() == quantity.roundToDouble()
            ? quantity.toInt().toString()
            : quantity.toString();
    return '$value ${item.unit.tr}'.trim();
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.count, required this.scale});
  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      count,
      (index) => SizedBox(
        height: 24 * scale,
        child: Column(
          children: [
            Container(
              width: 12 * scale,
              height: 12 * scale,
              padding: EdgeInsets.all(3 * scale),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: IngredientView.green, width: 1.2),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: IngredientView.green,
                ),
              ),
            ),
            if (index < count - 1)
              Expanded(
                child: Container(width: 1.2, color: IngredientView.green),
              ),
          ],
        ),
      ),
    ),
  );
}

class _IngredientGroups {
  const _IngredientGroups(this.main, this.seasonings);
  final List<MealIngredientModel> main;
  final List<MealIngredientModel> seasonings;

  factory _IngredientGroups.from(List<MealIngredientModel> source) {
    final main = <MealIngredientModel>[];
    final seasonings = <MealIngredientModel>[];
    const keywords = [
      'salt',
      'pepper',
      'oregano',
      'paprika',
      'cumin',
      'cinnamon',
      'turmeric',
      'thyme',
      'basil',
      'rosemary',
      'spice',
      'seasoning',
      'chili powder',
      'garlic powder',
      'onion powder',
    ];
    for (final item in source) {
      final name = item.name.toLowerCase();
      (keywords.any(name.contains) ? seasonings : main).add(item);
    }
    return _IngredientGroups(main, seasonings);
  }
}

// ================================================================
// BACKGROUND
// ================================================================

class _IngredientBackground extends StatelessWidget {
  const _IngredientBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appBackground,
      child: SizedBox.expand(
        child: Opacity(
          opacity: context.appIsDark ? 0.12 : 1,
          child: Image.asset(
            'assets/images/food_detail/background.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
