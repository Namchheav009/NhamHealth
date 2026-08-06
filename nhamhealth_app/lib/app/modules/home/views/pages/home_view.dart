import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/recommended_meal_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFFFFBFC),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFF00A651),
              onRefresh: controller.loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 105),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(),
                    SizedBox(height: 16),
                    HomeSearchBar(),
                    SizedBox(height: 16),
                    GreetingSection(),
                    SizedBox(height: 14),
                    AiRecommendationCard(),
                    SizedBox(height: 14),
                    DailySummaryCard(),
                    SizedBox(height: 12),
                    _RecommendedMealsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
          child: HomeBottomNavigation(),
        ),
      ),
    );
  }
}

class _RecommendedMealsSection extends GetView<HomeController> {
  const _RecommendedMealsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meals = controller.dashboard.value?.recommendedMeals ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recommended Meals',
                style: TextStyle(
                  color: Color(0xFF454545),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.refreshMeals,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00A651),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Refresh', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          if (controller.isLoading.value && meals.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF00A651),
                backgroundColor: Color(0xFFE9F7EE),
              ),
            )
          else if (meals.isNotEmpty) ...[
            const SizedBox(height: 7),
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder:
                    (_, index) => RecommendedMealCard(meal: meals[index]),
              ),
            ),
          ],
        ],
      );
    });
  }
}
