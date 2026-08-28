import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../bindings/meals/how_to_make_binding.dart';
import '../../bindings/meals/ingredient_binding.dart';
import '../../controllers/meals/food_detail_controller.dart';
import 'how_to_make_view.dart';
import 'ingredient_view.dart';

class FoodDetailView extends GetView<FoodDetailController> {
  const FoodDetailView({super.key});

  static const green = Color(0xFF00A651);
  static const darkGreen = Color(0xFF006B38);
  static const lightText = Color(0xFF7DB795);
  static const greyText = Color(0xFF909090);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          leadingWidth: 58,
          leading: IconButton(
            onPressed: controller.goBack,
            tooltip: 'Back'.tr,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 28,
              color: darkGreen,
            ),
          ),
          titleSpacing: 0,
          title: Text(
            'Food Detail'.tr,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        body: Stack(
          children: [
            const _FoodBackground(),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),

                        const SizedBox(height: 18),

                        _buildQuickStats(),

                        const SizedBox(height: 28),

                        _buildIngredientsSection(),

                        const SizedBox(height: 24),

                        _buildHowToMakeSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return SizedBox(
      height: 275,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative pale green circle
          Positioned(
            left: -125,
            top: -72,
            child: Container(
              width: 315,
              height: 315,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFFAF4),
              ),
            ),
          ),

          // Salad image
          Positioned(
            right: -82,
            top: 4,
            child: SizedBox(
              width: 260,
              height: 260,
              child: _MealHeroImage(imageUrl: controller.meal?.image ?? ''),
            ),
          ),

          Positioned(
            left: 2,
            top: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.meal?.category ?? 'fresh & Healthy'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6DA645),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: 195,
                  child: Text(
                    controller.meal?.name ?? 'Mix salad\nVegetables'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE4F0E8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, color: green, size: 17),
                      const SizedBox(width: 7),
                      Text(
                        'Light, crunchy & super tasty!'.tr,
                        style: const TextStyle(
                          color: Color(0xFF6B9E45),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                _nutritionValue(
                  barColor: Color(0xFFB4FFD0),
                  value: '${controller.meal?.calories ?? 240}',
                  label: 'Calories',
                ),

                const SizedBox(height: 6),

                _nutritionValue(
                  barColor: Color(0xFFA7C5E3),
                  value: '19',
                  label: 'gr Protein',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionValue({
    required Color barColor,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Container(width: 10, height: 44, color: barColor),

        const SizedBox(width: 13),

        Text(
          value,
          style: const TextStyle(
            color: green,
            fontSize: 29,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          label.tr,
          style: const TextStyle(
            color: lightText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  Widget _buildQuickStats() {
    final meal = controller.meal;
    final difficulty = meal?.difficulty;
    return Row(
      children: [
        Expanded(
          child: _FoodStatItem(
            icon: Icons.access_time_rounded,
            iconColor: green,
            iconBackground: Color(0xFFE7F5EB),
            borderColor: Color(0xFFA8DDB9),
            title: 'Cooking time',
            value: '${meal?.cookingTimeMinutes ?? 30} mins',
            valueColor: green,
          ),
        ),

        SizedBox(width: 8),

        Expanded(
          child: _FoodStatItem(
            icon: Icons.bar_chart_rounded,
            iconColor: Color(0xFFFFB51B),
            iconBackground: Color(0xFFFFF9E8),
            borderColor: Color(0xFFFFC94A),
            title: 'Difficulty',
            value: difficulty == null || difficulty.isEmpty
                ? 'Medium'
                : difficulty,
            valueColor: Color(0xFFFFB51B),
          ),
        ),

        SizedBox(width: 8),

        Expanded(
          child: _FoodStatItem(
            icon: Icons.groups_rounded,
            iconColor: green,
            iconBackground: Color(0xFFE7F5EB),
            borderColor: Color(0xFFA8DDB9),
            title: 'Servings',
            value: '${meal?.servings ?? 4} people',
            valueColor: green,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INGREDIENTS
  // ============================================================

  Widget _buildIngredientsSection() {
    return _sectionHeader(
      image: 'assets/images/food_detail/ingredent.png',
      title: 'Ingredients',
      subtitle: '6 healthy ingredients',
      onSeeMore:
          () => Get.to<void>(
            () => const IngredientView(),
            binding: IngredientBinding(),
            transition: Transition.rightToLeft,
          ),
    );
  }

  // ============================================================
  // HOW TO MAKE
  // ============================================================

  Widget _buildHowToMakeSection() {
    return _sectionHeader(
      image: 'assets/images/food_detail/howtomake.png',
      title: 'How to make',
      subtitle: 'Fresh & Healthy Mixed salad',
      onSeeMore:
          () => Get.to<void>(
            () => const HowToMakeView(),
            binding: HowToMakeBinding(),
            transition: Transition.rightToLeft,
          ),
    );
  }

  Widget _sectionHeader({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onSeeMore,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6D8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.tr,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: green,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle.tr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF76C48D)),
              ),
            ],
          ),
        ),

        TextButton(
          onPressed: onSeeMore,
          style: TextButton.styleFrom(
            foregroundColor: greyText,
            minimumSize: const Size(56, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text('See more'.tr, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ================================================================
// QUICK STAT ITEM
// ================================================================

class _FoodStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
  final String title;
  final String value;
  final Color valueColor;

  const _FoodStatItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.tr,
                maxLines: 1,
                style: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 10),
              ),

              const SizedBox(height: 5),

              Text(
                value.tr,
                maxLines: 1,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// BACKGROUND
// ================================================================

class _FoodBackground extends StatelessWidget {
  const _FoodBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/food_detail/background.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MealHeroImage extends StatelessWidget {
  const _MealHeroImage({required this.imageUrl});

  final String imageUrl;

  static const _fallbackImage = 'assets/images/food_detail/salad.png';

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() => Image.asset(
    _fallbackImage,
    fit: BoxFit.contain,
    alignment: Alignment.center,
  );
}
