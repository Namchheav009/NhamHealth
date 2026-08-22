import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/meals/ingredient_controller.dart';

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
        backgroundColor: const Color(0xFFFFFCFC),
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
        GestureDetector(
          onTap: controller.goBack,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, size: 30, color: darkGreen),
          ),
        ),

        const SizedBox(width: 11),

        const Text(
          'Ingredient',
          style: TextStyle(
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

              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: green,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      '6 healthy ingredients',
                      style: TextStyle(
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
  final IngredientModel ingredient;

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
          SizedBox(
            width: 74,
            height: 70,
            child: Image.asset(
              ingredient.image,
              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.eco_rounded,
                  size: 45,
                  color: Color(0xFF72C63C),
                );
              },
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
                  ingredient.name,
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
                  ingredient.description,
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

// ================================================================
// BACKGROUND
// ================================================================

class _IngredientBackground extends StatelessWidget {
  const _IngredientBackground();

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
