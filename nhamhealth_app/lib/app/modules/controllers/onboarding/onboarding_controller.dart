import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/onboarding/onboarding_item.dart';
import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentPage = 0.obs;

  final List<OnboardingItem> items = const [
    OnboardingItem(
      imagePath: 'assets/images/onboarding/onboarding1.png',
      title: 'onboarding.affordable_organic_goodness',
      description:
          'auth.get_affordable_organic_groceries_made_for_everyone_every_single_day',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding/onboarding2.png',
      title: 'onboarding.eat_with_purpose',
      accentTitle: 'onboarding.live_with_energy',
      description:
          'auth.every_meal_you_choose_is_a_step_toward_the_life_you_deserve',
      titleAboveImage: true,
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> nextPage() async {
    if (currentPage.value >= items.length - 1) {
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 0) {
      return;
    }

    await pageController.previousPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> skipToLastPage() async {
    Get.offAllNamed(AppRoutes.login);
  }

  void finishOnboarding() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
