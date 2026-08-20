import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../controllers/meal_controller.dart';
import '../../home/views/widgets/inner_shadow.dart';
import 'widgets/meal_bottom_navigation.dart';
import 'widgets/meal_card.dart';
import 'widgets/meal_slideshow.dart';

class MealView extends GetView<MealController> {
  const MealView({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,

        body: Stack(
          children: [
            const _MealBackground(),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(27, 24, 27, 125),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 16),

                        _buildSearch(),

                        const SizedBox(height: 14),

                        _buildCategories(),

                        const SizedBox(height: 22),

                        const MealSlideShow(),

                        const SizedBox(height: 23),

                        _buildMealGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // YOUR EXISTING NAVIGATION
        bottomNavigationBar: const SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
          child: MealBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHAM',
                  style: TextStyle(
                    height: 1.05,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPink,
                  ),
                ),
                Text(
                  'HEALTH',
                  style: TextStyle(
                    height: 1.05,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navigationGreen,
                  ),
                ),
              ],
            ),

            const Spacer(),

            IconButton(
              onPressed: () {},
              constraints: const BoxConstraints.tightFor(width: 42, height: 46),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.favorite_border_rounded,
                size: 28,
                color: AppColors.favoriteRed,
              ),
            ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  constraints: const BoxConstraints.tightFor(
                    width: 42,
                    height: 46,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 27,
                    color: Color(0xFF444444),
                  ),
                ),

                Positioned(
                  top: -1,
                  right: 1,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),

            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/homepage/profile.jpg',
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.search,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppColors.secondaryText,
                size: 25,
              ),
              SizedBox(width: 13),
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 11, color: AppColors.primaryText),
                  cursorColor: AppColors.primaryGreen,
                  decoration: InputDecoration(
                    hintText: 'Search for meals, tips or healthy groceries',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.categories.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          return Obx(() {
            final selected = controller.selectedCategory.value == index;

            return GestureDetector(
              onTap: () {
                controller.selectCategory(index);
              },
              child: Container(
                height: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navigationGreen : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        selected
                            ? AppColors.navigationGreen
                            : const Color(0xFFB4E0C3),
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.categories[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildMealGrid() {
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),

        itemCount: controller.meals.length,

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          childAspectRatio: 0.67,
        ),

        itemBuilder: (context, index) {
          return MealCard(
            meal: controller.meals[index],
            onFavorite: () {
              controller.toggleFavorite(index);
            },
          );
        },
      ),
    );
  }
}

class _MealBackground extends StatelessWidget {
  const _MealBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/background/bg.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
