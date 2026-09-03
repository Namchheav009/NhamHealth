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
      title: 'Affordable Organic\nGoodness',
      description:
          'Get affordable organic groceries made\n'
          'for everyone, every single day.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding/onboarding2.png',
      title: 'Eat with purpose',
      accentTitle: 'Live with energy.',
      description:
          'Every meal you choose is a step toward\n'
          'the life you deserve.',
      titleAboveImage: true,
      showBrandHeader: false,
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
