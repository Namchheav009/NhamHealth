import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../controllers/meals/ingredient_controller.dart';
import '../../models/meals/meal_model.dart';

class IngredientView extends GetView<IngredientController> {
  const IngredientView({super.key});

  static const Color green = Color(0xFF009C46);
  static const Color darkGreen = Color(0xFF006738);
  static const Color descriptionGreen = Color(0xFF79AD91);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            const _IngredientBackground(),

            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(29, 31, 29, 45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 38),

                        _buildIngredientHeader(),

                        const SizedBox(height: 37),

                        _buildIngredientList(),
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
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        AppBackButton(onPressed: controller.goBack),

        const SizedBox(width: AppBackButton.headerGap),

        Text(
          'Ingredient'.tr,
          style: const TextStyle(
            fontSize: 23,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INGREDIENT HERO HEADER
  // ============================================================

  Widget _buildIngredientHeader() {
    return SizedBox(
      height: 105,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT GREEN ICON
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5F1D0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Image.asset(
                    'assets/images/food_detail/ingredent.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 56),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients'.tr,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: green,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${controller.ingredients.length} ingredients'.tr,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF76C48E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildIngredientList() {
    return Column(
      children: List.generate(controller.ingredients.length, (index) {
        final ingredient = controller.ingredients[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == controller.ingredients.length - 1 ? 0 : 11,
          ),
          child: _IngredientCard(ingredient: ingredient),
        );
      }),
    );
  }
}

// ================================================================
// INGREDIENT CARD
// ================================================================

class _IngredientCard extends StatelessWidget {
  final MealIngredientModel ingredient;

  const _IngredientCard({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      // Fixed box size like your screenshot.
      height: 83,

      padding: const EdgeInsets.symmetric(horizontal: 13),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.87),

        borderRadius: BorderRadius.circular(21),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ----------------------------------------------
          // IMAGE
          // ----------------------------------------------
          ClipOval(
            child: SizedBox(
              width: 74,
              height: 70,
              child: _DynamicImage(url: ingredient.image),
            ),
          ),

          const SizedBox(width: 17),

          // ----------------------------------------------
          // TEXT
          // ----------------------------------------------
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: IngredientView.green,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  (ingredient.detail.isEmpty
                          ? 'Ingredient details unavailable'
                          : ingredient.detail)
                      .tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.18,
                    fontWeight: FontWeight.w500,
                    color: IngredientView.descriptionGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicImage extends StatelessWidget {
  const _DynamicImage({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFEAF6EE),
      child: const Icon(Icons.eco_rounded, size: 38, color: Color(0xFF72C63C)),
    );
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
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
